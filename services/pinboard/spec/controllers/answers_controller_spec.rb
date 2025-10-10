# frozen_string_literal: true

require 'spec_helper'

describe AnswersController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:user_id) { SecureRandom.uuid }
  let(:question) { create(:question) }
  let(:other_question) { create(:question) }
  let(:answer) do
    create(:answer, question_id: question.id, user_id:)
  end

  before do
    answer
    create_list(:answer, 2, question: other_question)
  end

  describe 'GET index' do
    let(:action) { -> { get :index, params: } }
    let(:params) { {} }

    it 'returns http success' do
      action.call
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      action.call
      expect(json.size).to eq(3)
    end

    it 'answers with answer resources' do
      action.call
      expect(json[0]).to eq(AnswerDecorator.new(answer).as_json.stringify_keys)
    end

    context 'answers for a question' do
      before { action.call }

      let(:params) { super().merge! question_id: question.id }

      it 'responds with a reduced list' do
        expect(json.size).to eq(1)
      end
    end

    context 'answers of a user' do
      before { action.call }

      let(:params) { super().merge! user_id: }

      it 'responds with a reduced list' do
        expect(json.size).to eq(1)
      end
    end

    describe 'sorting' do
      let(:params) { {question_id: question.id} }
      let!(:answer2) { create(:answer, question:, created_at: 3.days.ago) }
      let!(:answer3) { create(:answer, question:, created_at: 2.days.ago) }
      let!(:answer4) { create(:answer, question:, created_at: 1.day.ago) }

      before do
        create_list(:vote, 3, :for_answer, votable: answer)
        create_list(:vote, 2, :for_answer, votable: answer2)
        create_list(:vote, 1, :for_answer, votable: answer4)
      end

      context 'default' do
        it 'returns all answers, highest-voted first' do
          action.call
          expect(json.pluck('id')).to eq [answer.id, answer2.id, answer4.id, answer3.id]
        end
      end

      context 'sort=votes' do
        let(:params) { {**super(), sort: 'votes'} }

        it 'returns all answers, highest-voted first' do
          action.call
          expect(json.pluck('id')).to eq [answer.id, answer2.id, answer4.id, answer3.id]
        end
      end

      context 'sort=created_at' do
        let(:params) { {**super(), sort: 'created_at'} }

        it 'returns all answers, oldest first' do
          action.call
          expect(json.pluck('id')).to eq [answer2.id, answer3.id, answer4.id, answer.id]
        end
      end

      context 'any invalid value' do
        let(:params) { {**super(), sort: 'invalid'} }

        it 'returns with HTTP 400 (Bad Request)' do
          action.call
          expect(response).to have_http_status :bad_request
        end
      end
    end

    describe 'params include :watch_for_user_id' do
      before { action.call }

      let(:params) { super().merge!(watch_for_user_id: question.user_id) }

      it 'answers have a read state' do
        expect(json).to all(include('read'))
      end

      context 'user is watching' do
        before { create(:watch, question_id: question.id, user_id: question.user_id) }

        context 'a new answer was created' do
          before do
            create(:answer, text: "I'm the new answer", question_id: question.id)
            action.call # refresh response.body
          end

          context 'then the new answer' do
            subject(:new_answer) { json.last }

            it 'is considered unread' do
              expect(new_answer['text']).to eq "I'm the new answer"
              expect(new_answer['read']).to be_falsy
            end
          end

          context 'but the old answer' do
            subject(:old_answer) { json.first }

            it 'is still considered read' do
              expect(old_answer['id']).to eq answer.id # the old answer
              expect(old_answer['read']).to be_truthy
            end
          end
        end
      end
    end

    describe 'vote status for user' do
      let(:requested_user_id) { '00000001-3300-4444-9999-000000000002' }
      let(:other_user_id) { '00000001-3300-4444-9999-000000000001' }
      let(:vote_value) { 1 }
      let(:params) { super().merge! vote_value_for_user_id: requested_user_id }

      let!(:answer_with_other_vote) { create(:answer, question:) }
      let!(:answer_voted_by_user) { create(:answer, question:) }

      before do
        create(:vote, votable_id: answer_voted_by_user.id,
          value: vote_value,
          user_id: requested_user_id,
          votable_type: 'Answer')

        create(:vote, votable_id: answer_with_other_vote.id,
          value: vote_value,
          user_id: other_user_id,
          votable_type: 'Answer')

        action.call
      end

      describe 'right vote values according to requested user' do
        subject do
          JSON.parse(response.body).find {|answer| answer['id'] == answer_id }
        end

        context 'answer_voted_by_user' do
          let(:answer_id) { answer_voted_by_user.id }

          describe 'vote_value_for_requested_user' do
            its(['vote_value_for_requested_user']) { is_expected.to eq vote_value }
          end
        end

        context 'answer_not_voted_by_user_but_others' do
          let(:answer_id) { answer_with_other_vote.id }

          describe 'vote_value_for_requested_user' do
            its(['vote_value_for_requested_user']) { is_expected.to eq 0 }
          end
        end

        context 'answer_not_voted' do
          let(:answer_id) { answer.id }

          describe 'vote_value_for_requested_user' do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq 0 }
          end
        end
      end
    end

    context 'with deleted comments' do
      before do
        create(:answer, deleted: true)

        action.call
      end

      it 'returns only undeleted answers' do
        expect(json).to have(3).item
      end

      context 'with deleted param' do
        let(:params) { super().merge! deleted: true }

        it 'returns all questions' do
          expect(json).to have(4).items
        end
      end
    end
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show, params: {id: answer.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with an answer resource' do
      get :index, params: {question_id: question.id}
      expect(json[0]).to eq(AnswerDecorator.new(answer).as_json.stringify_keys)
    end

    describe 'text' do
      let(:markup) { "Headline\ns3://xikolo-pinboard/courses/1/thread/1/1/hans.jpg" }
      let(:answer) { create(:answer, question_id: question.id, text: markup) }

      let(:params) { {id: answer.id} }

      before { get :show, params: }

      context 'when meant for rendering' do
        it 'exposes markup with public URLs' do
          expect(json['text']).to eq "Headline\nhttps://s3.xikolo.de/xikolo-pinboard/courses/1/thread/1/1/hans.jpg"
        end
      end

      context 'when meant for the input field' do
        it 'returns the markup split into markup and urls' do
          get :show, params: {id: answer.id, text_purpose: 'input'}
          expect(json['text']).to eq(
            'markup' => markup,
            'url_mapping' => {
              's3://xikolo-pinboard/courses/1/thread/1/1/hans.jpg' =>
                'https://s3.xikolo.de/xikolo-pinboard/courses/1/thread/1/1/hans.jpg',
            },
            'other_files' => {
              's3://xikolo-pinboard/courses/1/thread/1/1/hans.jpg' =>
                'hans.jpg',
            }
          )
        end
      end
    end

    describe 'vote status for user' do
      let(:requested_user_id) { '00000001-3300-4444-9999-000000000002' }
      let(:other_user_id) { '00000001-3300-4444-9999-000000000001' }
      let(:vote_value) { 1 }
      let(:params) { default_params.merge(vote_value_for_user_id: requested_user_id) }

      let!(:answer_with_other_vote) { create(:answer, question:) }
      let!(:answer_voted_by_user) { create(:answer, question:) }

      before do
        create(:vote, votable_id: answer_voted_by_user.id,
          value: vote_value,
          user_id: requested_user_id,
          votable_type: 'Answer')

        create(:vote, votable_id: answer_with_other_vote.id,
          value: vote_value,
          user_id: other_user_id,
          votable_type: 'Answer')
      end

      describe 'right vote values according to requested user' do
        subject { json }

        let(:params) { super().merge(id: answer_id) }

        before { get :show, params: }

        context 'answer_voted_by_user' do
          let(:answer_id) { answer_voted_by_user.id }

          describe 'vote_value_for_requested_user' do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq vote_value }
          end
        end

        context 'answer_not_voted_by_user_but_others' do
          let(:answer_id) { answer_with_other_vote.id }

          describe 'vote_value_for_requested_user' do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq 0 }
          end
        end

        context 'answer_not_voted' do
          let(:answer_id) { answer.id }

          describe 'vote_value_for_requested_user' do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq 0 }
          end
        end
      end
    end
  end

  describe 'POST create' do
    subject(:creation) { post :create, params: }

    let(:params) { answer }
    let(:answer) { attributes_for(:answer, question_id: question.id) }

    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(
        :course, :get, "/courses/#{question.course_id}"
      ).to_return Stub.json({
        id: question.course_id,
        title: 'My course',
        course_code: 'my_course',
        forum_is_locked: false,
      })
    end

    it { is_expected.to have_http_status :created }

    it 'creates an answer on create' do
      expect { creation }.to change(Answer, :count).by(1)
    end

    it 'answers with answer' do
      creation

      expect(json['text']).not_to be_nil
      expect(json['text']).to eq(attributes_for(:answer)[:text])
    end

    context 'with image references' do
      let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
      let(:answer) { super().merge text: }
      let(:cid) { UUID4(question.course_id).to_s(format: :base62) }

      it 'stores valid upload and creates a new richtext' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                         /courses/#{cid}/topics/[0-9a-zA-Z]+/
                         [0-9a-zA-Z]+/foo.jpg}x
        stub_request(:head, store_regex).and_return(status: 404)
        stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
        expect { creation }.to change(Answer, :count).by(1)
        expect(Answer.find(json['id']).text).to include 's3://xikolo-pinboard'
      end

      it 'rejects invalid upload and does not creates a new page' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )

        creation

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'text' => ['rtfile_rejected']
      end

      it 'rejects upload on storage errors' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                         /courses/#{cid}/topics/[0-9a-zA-Z]+/
                         [0-9a-zA-Z]+/foo.jpg}x
        stub_request(:head, store_regex).and_return(status: 404)
        stub_request(:put, store_regex).and_return(status: 503)

        creation

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'text' => ['rtfile_error']
      end
    end

    context 'with attachment upload' do
      let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
      let(:answer) { super().merge attachment_upload_id: upload_id }
      let(:cid) { UUID4(question.course_id).to_s(format: :base62) }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg'
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          'prefix=uploads%2F83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa').to_return(
            status: 200,
            headers: {'Content-Type' => 'Content-Type: application/xml'},
            body: <<~XML)
              <?xml version="1.0" encoding="UTF-8"?>
              <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <Name>xikolo-uploads</Name>
                <Prefix>uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa</Prefix>
                <IsTruncated>false</IsTruncated>
                <Contents>
                  <Key>uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
      end

      it 'stores file and use it afterwards' do
        stub_request(:head, file_url)
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                           /courses/#{cid}/topics/[0-9a-zA-Z]+/
                           [0-9a-zA-Z]+/image.jpg}x
        store_stub = stub_request(:put, store_regex).to_return(status: 200, body: '<xml></xml>')

        expect { creation }.to change(Answer, :count).by(1)
        expect(store_stub).to have_been_requested
        expect(Answer.find(json['id']).attachment_uri).not_to be_nil
      end

      it 'rejects invalid attachments' do
        stub_request(:head, file_url)
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )

        creation

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['invalid upload']
      end

      it 'handles S3 errors during upload validating' do
        stub_request(:head, file_url).to_return(
          status: 403
        )
        creation

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['could not process file upload']
      end

      it 'handles S3 errors during upload copying' do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )

        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                           /courses/#{cid}/topics/[0-9a-zA-Z]+/
                           [0-9a-zA-Z]+/image.jpg}x
        stub_request(:put, store_regex).to_return(status: 403)

        creation

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['could not process file upload']
      end
    end

    it 'creates exactly one subscription with answer' do
      expect { creation }.to change(Subscription, :count).by(1)
    end
  end

  describe 'PUT update' do
    subject { answer; request; answer.reload }

    let(:answer) { create(:answer) }
    let(:attributes) { attributes_for(:answer) }
    let(:additional_params) { {text: 'test'} }
    let(:request) { put :update, params: attributes.merge(additional_params).merge(id: answer.id) }

    it 'responds with 204 No Content' do
      request
      expect(response).to have_http_status :no_content
    end

    describe '#text' do
      subject { super().text }

      it { is_expected.to eq 'test' }
    end

    context 'with image references' do
      subject(:modification) { request }

      let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
      let(:additional_params) { {text:} }
      let(:cid) { UUID4(answer.question.course_id).to_s(format: :base62) }

      it 'stores valid upload and creates a new richtext' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                         /courses/#{cid}/topics/[0-9a-zA-Z]+/
                         [0-9a-zA-Z]+/foo.jpg}x
        stub_request(:head, store_regex).and_return(status: 404)
        stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')

        expect { modification; answer.reload }.to change(answer, :text)
        expect(answer.text).to include 's3://xikolo-pinboard'
      end

      it 'rejects invalid upload and does not creates a new page' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )

        modification

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'text' => ['rtfile_rejected']
      end

      it 'rejects upload on storage errors' do
        stub_request(
          :head,
          'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
        ).and_return(
          status: 200,
          headers: {
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_text',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                         /courses/#{cid}/topics/[0-9a-zA-Z]+/
                         [0-9a-zA-Z]+/foo.jpg}x
        stub_request(:head, store_regex).and_return(status: 404)
        stub_request(:put, store_regex).and_return(status: 503)

        modification

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'text' => ['rtfile_error']
      end
    end

    context 'with attachment upload' do
      let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
      let(:additional_params) { {attachment_upload_id: upload_id} }
      let(:cid) { UUID4(answer.question.course_id).to_s(format: :base62) }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg'
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          'prefix=uploads%2F83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa').to_return(
            status: 200,
            headers: {'Content-Type' => 'Content-Type: application/xml'},
            body: <<~XML)
              <?xml version="1.0" encoding="UTF-8"?>
              <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                <Name>xikolo-uploads</Name>
                <Prefix>uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa</Prefix>
                <IsTruncated>false</IsTruncated>
                <Contents>
                  <Key>uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg</Key>
                  <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                  <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                </Contents>
              </ListBucketResult>
            XML
      end

      it 'stores file and use it afterwards' do
        stub_request(:head, file_url)
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                           /courses/#{cid}/topics/[0-9a-zA-Z]+/
                           [0-9a-zA-Z]+/image.jpg}x
        store_stub = stub_request(:put, store_regex).to_return(status: 200, body: '<xml></xml>')

        expect { request; answer.reload }.to change(answer, :attachment_uri)
        expect(store_stub).to have_been_requested
      end

      it 'removes an old attachment' do
        answer.update attachment_uri: 's3://xikolo-pinboard/courses/1/threads/1/1/otto.jpg'
        stub_request(:head, file_url)
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                           /courses/#{cid}/topics/[0-9a-zA-Z]+/
                           [0-9a-zA-Z]+/image.jpg}x
        store_stub = stub_request(:put, store_regex).to_return(status: 200, body: '<xml></xml>')
        cleanup_stub = stub_request(:delete, 'https://s3.xikolo.de/xikolo-pinboard/courses/1/threads/1/1/otto.jpg')
          .to_return(status: 200)

        expect { request; answer.reload }.to change(answer, :attachment_uri)
        expect(store_stub).to have_been_requested
        expect(cleanup_stub).to have_been_requested
      end

      it 'rejects invalid attachments' do
        stub_request(:head, file_url)
          .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )

        request

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['invalid upload']
      end

      it 'handles S3 errors during upload validating' do
        stub_request(:head, file_url).to_return(
          status: 403
        )

        request

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['could not process file upload']
      end

      it 'handles S3 errors during upload copying' do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'pinboard_commentable_attachment',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )

        store_regex = %r{https://s3.xikolo.de/xikolo-pinboard
                           /courses/#{cid}/topics/[0-9a-zA-Z]+/
                           [0-9a-zA-Z]+/image.jpg}x
        stub_request(:put, store_regex).to_return(status: 403)

        request

        expect(response).to have_http_status :unprocessable_entity
        expect(json['errors']).to eq 'attachment_upload_id' => ['could not process file upload']
      end
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: {id: answer.id} }

    it 'changes the deleted flag to true' do
      expect { action }.to change { answer.reload.deleted }.from(false).to(true)
    end

    it 'does not delete the question record' do
      expect { action }.not_to change(Answer, :count)
    end
  end
end
