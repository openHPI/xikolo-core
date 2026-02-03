# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::CommentsController, type: :controller do
  routes { PinboardService::Engine.routes }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:question) { create(:'pinboard_service/question') }
  let(:comment) { create(:'pinboard_service/comment', commentable: question) }
  let(:attributes) { attributes_for(:'pinboard_service/comment', commentable: question) }
  let(:unvoted_uncommented_question) { create(:'pinboard_service/unvoted_uncommented_question') }

  let(:answer) { create(:'pinboard_service/answer') }
  let(:answer_comment) { create(:'pinboard_service/comment', commentable: answer) }
  let(:answer_comment_attributes) { attributes_for(:'pinboard_service/comment', commentable: answer) }

  before do
    comment
    unvoted_uncommented_question
  end

  describe "GET 'index'" do
    let(:action) { -> { get :index, params: } }
    let(:params) { {} }

    before { action.call }

    it 'returns http success' do
      expect(response).to have_http_status :ok
    end

    it 'returns a list' do
      expect(json).to have(1).item
    end

    it 'answers with comment resources' do
      expect(json.first).to eq(PinboardService::CommentDecorator.new(comment).as_json.stringify_keys)
    end

    context 'with deleted comments' do
      before do
        create(:'pinboard_service/comment', deleted: true)

        action.call
      end

      it 'returns only undeleted comments' do
        expect(json).to have(1).item
      end

      context 'with deleted param' do
        let(:params) { super().merge! deleted: true }

        it 'returns all questions' do
          expect(json).to have(2).items
        end
      end
    end

    context 'for a user' do
      let(:user_id) { SecureRandom.uuid }
      let(:params) { super().merge! user_id: }

      before do
        comment.update!(user_id:)
        create_list(:'pinboard_service/comment', 5)

        action.call
      end

      it 'returns a reduced list' do
        expect(JSON.parse(response.body).size).to eq(1)
      end

      it 'returns comments by the user' do
        expect(JSON.parse(response.body).first['user_id']).to eq user_id
      end
    end

    context 'with many comments' do
      before do
        create_list(:'pinboard_service/comment', 51, :for_answer, commentable: answer) # rubocop:disable FactoryBot/ExcessiveCreateList
      end

      # a client spec using question.comments / enqueue_comments should test for more than 50 comments
      it 'loads first 50 comments' do
        get :index
        expect(json.size).to eq(50)
      end
    end

    describe 'params include :watch_for_user_id' do
      let(:params) { super().merge!(watch_for_user_id: question.user_id) }

      it 'comments have a read state' do
        expect(json).to all(include('read'))
      end

      context 'user is watching' do
        before { create(:'pinboard_service/watch', question_id: question.id, user_id: question.user_id) }

        context 'new comment on question' do
          before do
            create(:'pinboard_service/comment', text: "I'm the new comment", commentable: question)
            action.call # refresh response.body
          end

          context 'then the new comment' do
            subject(:new_comment) { json.last }

            it 'is considered unread' do
              expect(new_comment['text']).to eq "I'm the new comment"
              expect(new_comment['read']).to be_falsy
            end
          end

          context 'but the old comment' do
            subject(:old_comment) { json.first }

            it 'is still considered read' do
              expect(old_comment['id']).to eq comment.id # the old comment
              expect(old_comment['read']).to be_truthy
            end
          end
        end

        context 'new comment on answer of a question' do
          let(:answer) { create(:'pinboard_service/answer', question:) }

          before do
            create(:'pinboard_service/comment', :for_answer, text: "I'm the new comment", commentable: answer)
            action.call # and get the response once again
          end

          context 'then the new comment' do
            subject(:new_comment) { json.last }

            it 'is considered unread' do
              expect(new_comment['text']).to eq "I'm the new comment"
              expect(new_comment['read']).to be_falsy
            end
          end

          context 'but the old comment' do
            subject(:old_comment) { json.first }

            it 'is still considered read' do
              expect(old_comment['id']).to eq comment.id # the old answer
              expect(old_comment['read']).to be_truthy
            end
          end
        end
      end
    end
  end

  describe "GET 'show'" do
    before { get :show, params: {id: comment.id} }

    it 'returns http success' do
      expect(response).to have_http_status :ok
    end

    it 'answers with a comment resource' do
      expect(json).to eq(PinboardService::CommentDecorator.new(comment).as_json.stringify_keys)
    end

    describe 'text' do
      let(:markup) { "Headline\ns3://xikolo-pinboard/courses/1/thread/1/1/hans.jpg" }
      let(:comment) { create(:'pinboard_service/comment', text: markup) }
      let(:params) { {id: comment.id} }

      before { get :show, params: }

      context 'when meant for rendering' do
        it 'exposes markup with public URLs' do
          expect(json['text']).to eq "Headline\nhttps://s3.xikolo.de/xikolo-pinboard/courses/1/thread/1/1/hans.jpg"
        end
      end

      context 'when meant for the input field' do
        let(:params) { super().merge(text_purpose: 'input') }

        it 'returns the markup split into markup and URLs' do
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
  end

  describe "POST 'create'" do
    subject(:response) { post :create, params: }

    before do
      Stub.request(
        :course, :get, "/courses/#{question.course_id}"
      ).to_return Stub.json({
        id: question.course_id,
        title: 'My course',
        course_code: 'my_course',
        forum_is_locked: false,
      })

      Stub.request(
        :account, :get, "/users/#{attributes[:user_id]}"
      ).to_return Stub.json({
        id: attributes[:user_id],
        name: 'Egon Olsen',
      })
    end

    context 'with a question' do
      let(:params) do
        {
          commentable_type: 'Question',
          commentable_id: question.id,
          user_id: question.user_id,
          text: 'This is a comment. Probably.',
        }
      end

      it { is_expected.to have_http_status :created }

      it 'creates a comment on create' do
        expect { response }.to change(PinboardService::Comment, :count).by(1)
      end

      it 'responds with a comment resource' do
        expect(json).to include \
          'text' => 'This is a comment. Probably.',
          'commentable_id' => question.id,
          'commentable_type' => 'Question'
      end

      context 'with image references' do
        let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
        let(:params) { super().merge text: }
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

          expect { response }.to change(PinboardService::Comment, :count).by(1)
          expect(PinboardService::Comment.find(json['id']).text).to include 's3://xikolo-pinboard'
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

          expect(json['errors']).to eq 'text' => ['rtfile_error']
        end
      end

      context 'with notification' do
        let(:params) { super().merge(notification: {notify: 'true'}) }

        before do
          Stub.request(
            :notification, :post, '/events'
          ).to_return Stub.response(status: 201)
          Stub.request(
            :account, :get, "/users/#{question.user_id}"
          ).to_return Stub.json({
            id: question.user_id,
            name: 'Benny Frandsen',
          })
        end

        it 'creates subscription with answer' do
          expect { response }.to change(PinboardService::Subscription, :count).from(0).to(1)
        end
      end
    end

    context 'with an answer' do
      let(:params) do
        {
          commentable_type: 'Answer',
          commentable_id: answer.id,
          user_id: answer.user_id,
          text: 'This is a comment. Probably.',
        }
      end

      it { is_expected.to have_http_status :created }

      context 'with image references' do
        let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
        let(:params) { super().merge text: }
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

          expect { response }.to change(PinboardService::Comment, :count).by(1)
          expect(PinboardService::Comment.find(json['id']).text).to include 's3://xikolo-pinboard'
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

          expect(json['errors']).to eq 'text' => ['rtfile_error']
        end
      end
    end
  end

  describe "PUT 'update'" do
    subject { request; comment.reload }

    let(:additional_params) { {text: 'test'} }
    let(:request) { put :update, params: attributes.merge(additional_params).merge(id: comment.id) }

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
      let(:additional_params) { super().merge text: }
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

        expect { modification; comment.reload }.to change(comment, :text)
        expect(comment.text).to include 's3://xikolo-pinboard'
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
  end

  describe "DELETE 'destroy'" do
    before { comment }

    let(:request) { delete :destroy, params: {id: comment.id} }

    it 'responds with 204 No Content' do
      request
      expect(response).to have_http_status :no_content
    end

    it 'changes the deleted flag to true' do
      request
      expect(comment.reload.deleted).to be_truthy
    end

    it 'does not delete the question record' do
      expect { request }.not_to change(PinboardService::Comment, :count)
    end
  end
end
