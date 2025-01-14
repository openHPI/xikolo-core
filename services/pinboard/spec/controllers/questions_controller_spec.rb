# frozen_string_literal: true

require 'spec_helper'

describe QuestionsController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:question) { create(:question_with_implicit_tags) }
  let(:deleted_question) { create(:deleted_question) }

  before { question }

  describe "GET 'index'" do
    let(:action) { get :index, params: }

    it 'returns all existing questions' do
      get :index, format: :json
      expect(json).not_to be_empty
      expect(json.size).to eq(1)
    end

    describe 'querying for a course' do
      subject(:index) { get :index, params: {course_id: question.course_id}.merge(additional_params) }

      let(:additional_params) { {} }

      it 'returns http success' do
        index
        expect(response).to have_http_status :ok
      end

      it 'returns a list' do
        index
        expect(json.size).to eq(1)
      end

      it 'answers with question resources' do
        index
        expect(json[0]).to eq(QuestionDecorator.new(question, context: {collection: true}).as_json.stringify_keys)
      end

      describe 'with an empty string taglist as an argument' do
        let(:additional_params) { {taglist: ''} }

        it 'still works' do
          index
          expect(response).to be_successful
        end
      end

      context 'when learning room questions exist' do
        before { create(:learning_room_question) }

        it 'does not include the learning room question' do
          index
          expect(json.size).to eq 1
          expect(json.first['id']).to eq question.id
        end
      end
    end

    describe 'querying for a tag' do
      subject(:index) { get :index, params: {course_id: question.course_id, taglist: tags} }

      let(:question) { create(:question_with_tags) }
      let(:tag) { question.tags.first }
      let(:tags) { {code_does_not_care_about_keys: tag.id} }

      it 'is succesful' do
        index
        expect(response).to be_successful
      end

      it 'returns one question' do
        index
        expect(json.size).to eq(1)
      end

      it 'returns our question' do
        index
        expect(json.first['id']).to eq question.id
      end

      it 'return our question decorated' do
        index
        expect(json[0]).to eq(QuestionDecorator.new(question, context: {collection: true}).as_json.stringify_keys)
      end

      it 'does not return questions that do not have that tag' do
        create(:question)
        index
        expect(json.size).to eq(1)
      end

      it 'does return more if tagged' do
        create(:question, tags: [tag])
        index
        expect(json.size).to eq(2)
      end
    end

    describe 'for a learning room' do
      subject(:index) { get :index, params: {learning_room_id: question.learning_room_id} }

      let(:question) { create(:learning_room_question) }

      it 'is succesful' do
        index
        expect(response).to be_successful
      end

      it 'has one item' do
        index
        expect(json.size).to eq(1)
      end

      it 'has the right learning_room_id' do
        index
        expect(json.first['learning_room_id']).to eq question.learning_room_id
      end

      context 'when questions in the course pinboard exist' do
        before { create(:question) }

        it 'does not include the course question' do
          index
          expect(json.size).to eq 1
          expect(json.first['id']).to eq question.id
        end
      end
    end

    describe 'filter by given tag names and course' do
      subject { -> { action } }

      let(:course_id) { '00000001-3300-4444-9999-000000000001' }
      let(:tag1) { create(:explicit_tag, name: 'tag 1', course_id:) }
      let(:tag2) { create(:explicit_tag, name: 'tag 2', course_id:) }
      let(:tag3) { create(:explicit_tag, name: 'tag 3', course_id:) }

      let(:first_question_with_tags_1_and_2)  { create(:question, course_id:, tags: [tag1, tag2], title: 'With tags 1 and 2') }
      let(:second_question_with_tags_1_and_2) { create(:question, course_id:, tags: [tag1, tag2], title: 'Also with tags 1 and 2') }
      let(:question_with_tags_1_and_2_and_3) { create(:question, course_id:, tags: [tag1, tag2, tag3], title: 'With tags 1, 2 and 3') }
      let(:question_with_tags_2_and_3) { create(:question, course_id:, tags: [tag2, tag3], title: 'Only with tags 2 and 3') }

      let(:params) { {course_id:, with_tagnames: {'0' => tag1.name, '1' => tag2.name}} }

      before do
        first_question_with_tags_1_and_2; second_question_with_tags_1_and_2
        question_with_tags_1_and_2_and_3; question_with_tags_2_and_3
      end

      describe '#call' do
        subject { super().call }

        it { is_expected.to be_successful }
      end

      describe 'response' do
        subject(:index_response) { json }

        before { action }

        it { is_expected.to be_a Array }

        it 'has 3 items' do
          expect(index_response.size).to eq(3)
        end

        it 'has correct questions' do
          expect(index_response.pluck('title')).to contain_exactly(first_question_with_tags_1_and_2.title, second_question_with_tags_1_and_2.title, question_with_tags_1_and_2_and_3.title)
        end
      end
    end

    describe 'filter by age' do
      subject { -> { action } }

      let(:created_after) { 4.days.ago }
      let!(:older_questions) do
        create_list(:question, 3,
          created_at: (created_after - 1.day))
      end
      let(:question) { older_questions.first }
      let!(:newer_questions) do
        create_list(:question, 2,
          created_at: (created_after + 1.day))
      end

      let(:params) { {course_id: question.course_id, created_after: created_after.iso8601} }

      describe '#call' do
        subject { super().call }

        it { is_expected.to be_successful }
      end

      describe 'response' do
        subject(:index_response) { json }

        before do
          action
        end

        it { is_expected.to be_a Array }

        it 'has 2 items' do
          expect(index_response.size).to eq(2)
        end

        it 'has correct questions' do
          expect(index_response.pluck('id')).to match_array newer_questions.map(&:id)
        end
      end
    end

    describe 'for a specific user' do
      let(:params) { {user_id:} }
      let(:user_id) { SecureRandom.uuid }
      let(:question) { create(:question, user_id:) }

      before { create_list(:question, 5) }

      it 'has one item' do
        action
        expect(json.size).to eq(1)
      end

      it 'has the right user_id' do
        action
        expect(json.first['user_id']).to eq user_id
      end
    end

    describe 'vote status for user' do
      let(:course_id) { '00000001-3300-4444-9999-000000000001' }
      let(:requested_user_id) { '00000001-3300-4444-9999-000000000002' }
      let(:other_user_id) { '00000001-3300-4444-9999-000000000001' }
      let(:vote_value) { 1 }
      let(:params) { default_params.merge(vote_value_for_user_id: requested_user_id) }

      let!(:question_with_other_vote) { create(:question, course_id:) }
      let!(:question_voted_by_user) { create(:question, course_id:) }

      before do
        create(:vote, votable_id: question_voted_by_user.id,
          value: vote_value,
          user_id: requested_user_id,
          votable_type: 'Question')

        create(:vote, votable_id: question_with_other_vote.id,
          value: vote_value,
          user_id: other_user_id,
          votable_type: 'Question')
      end

      context 'in a course' do
        let(:params) { super().merge(course_id:) }

        before { get :index, params: }

        it 'responds with a list' do
          expect(json.size).to eq(3)
        end

        describe 'right vote values according to requested user' do
          subject { json.find {|question| question['id'] == question_id } }

          let(:question_id) { '' }

          context 'question_voted_by_user' do
            let(:question_id) { question_voted_by_user.id }

            describe "['vote_value_for_requested_user']" do
              subject { super()['vote_value_for_requested_user'] }

              it { is_expected.to eq vote_value }
            end
          end

          context 'question_not_voted_by_user_but_others' do
            let(:question_id) { question_with_other_vote.id }

            describe "['vote_value_for_requested_user']" do
              subject { super()['vote_value_for_requested_user'] }

              it { is_expected.to eq 0 }
            end
          end

          context 'question_not_voted' do
            let(:question_id) { question.id }

            describe "['vote_value_for_requested_user']" do
              subject { super()['vote_value_for_requested_user'] }

              it { is_expected.to eq 0 }
            end
          end
        end
      end
    end

    describe 'read state for user' do
      let(:action) { -> { get :index, params: } }
      let(:params) { {course_id: question.course_id} }

      before { action.call }

      it 'does not have a read state' do
        json.each do |q|
          expect(q).not_to include('read')
        end
      end

      context 'with watch_for_user_id' do
        let(:params) { super().merge!(watch_for_user_id: question.user_id) }

        let(:first_question) { json_reloaded.first }

        it 'has a read state' do
          expect(json).to all include('read')
        end

        it 'is not read' do
          expect(first_question['read']).to be_falsy
        end

        context 'with watch' do
          before { create(:watch, question_id: question.id, user_id: question.user_id) }

          it 'is read' do
            action.call
            expect(first_question['read']).to be true
          end

          context 'with changes in the question' do
            it 'is not read' do
              question.touch
              action.call
              expect(first_question['read']).to be_falsy
            end
          end
        end
      end
    end

    context 'for technical issues' do
      subject(:index_request) { get :index, params: default_params.merge(course_id: question.course_id).merge(additional_params) }

      let!(:technical_question) { create(:technical_question) }
      let(:additional_params) { {} }

      before { index_request }

      it 'delivers one question' do
        expect(json.size).to eq(1)
      end

      it 'does not deliver the technical question by default' do
        expect(json.first['title']).to eq question.title
      end

      context 'with without_ref_resource param' do
        let(:additional_params) { {without_ref_resource: 'true'} }

        it 'delivers two questions' do
          expect(json.size).to eq(2)
        end

        it 'delivers the technical question' do
          expect(json.pluck('title')).to include technical_question.title
        end

        it 'delivers the other question' do
          expect(json.pluck('title')).to include question.title
        end
      end
    end

    context 'filter for unanswered' do
      subject(:index_response) do
        get :index, params: {course_id: unanswered_questions.first.course_id, unanswered: 'true'}
        json
      end

      let(:question) { nil }
      let!(:unanswered_questions) { create_list(:question, 3) }

      before { create_list(:question_with_accepted_answer, 3) }

      it 'returns only unanswered questions' do
        expect(index_response.pluck('id')).to \
          match_array unanswered_questions.map(&:id)
      end
    end

    describe 'order' do
      subject { json }

      let(:course_id) { SecureRandom.uuid }
      let(:params) { {course_id:} }

      before { action }

      describe 'random' do
        let(:question) { nil }
        let!(:questions) { create_list(:question, 3) }
        let(:course_id) { questions.first.course_id }
        let(:params) { super().merge question_filter_order: 'random' }

        it 'returns 3 questions' do
          expect(json.size).to eq 3
        end
      end
    end

    context 'with deleted questions' do
      before { deleted_question }

      it 'returns only undeleted questions' do
        get :index
        expect(json).to have(1).item
      end

      context 'with deleted param' do
        it 'returns all questions' do
          get :index, params: {deleted: true}
          expect(json).to have(2).items
        end
      end
    end

    context 'with blocked and reviewed questions' do
      subject { json }

      before do
        create(:question, workflow_state: :blocked)
        create(:question, workflow_state: :reviewed)

        get :index
      end

      it { is_expected.to have(2).item }

      context 'with blocked param' do
        before { get :index, params: {blocked: true} }

        it { is_expected.to have(3).item }
      end
    end
  end

  describe "GET 'show'" do
    it 'returns http success' do
      get :show, params: {id: question.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with a question resource' do
      get :show, params: {id: question.id}
      expect(json).to eq(QuestionDecorator.new(question).as_json.stringify_keys)
    end

    describe 'text' do
      let(:markup) { "Headline\ns3://xikolo-pinboard/courses/1/thread/1/1/hans.jpg" }
      let(:question) { create(:question_with_implicit_tags, text: markup) }
      let(:params) { {id: question.id} }

      before { get :show, params: }

      context 'when meant for rendering' do
        it 'exposes markup with public URLs' do
          expect(json['text']).to eq "Headline\nhttps://s3.xikolo.de/xikolo-pinboard/courses/1/thread/1/1/hans.jpg"
        end
      end

      context 'when meant for editing' do
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

      context 'when meant for displaying' do
        let(:params) { super().merge(text_purpose: 'display') }

        it 'returns the markup with URIs' do
          expect(json['text']).to eq(markup)
        end
      end
    end

    describe 'vote status for user' do
      let(:course_id) { '00000001-3300-4444-9999-000000000001' }
      let(:requested_user_id) { '00000001-3300-4444-9999-000000000002' }
      let(:other_user_id) { '00000001-3300-4444-9999-000000000001' }
      let(:vote_value) { 1 }
      let(:params) { default_params.merge(vote_value_for_user_id: requested_user_id) }

      let!(:question_with_other_vote) { create(:question, course_id:) }
      let!(:question_voted_by_user) { create(:question, course_id:) }

      before do
        create(:vote, votable_id: question_voted_by_user.id,
          value: vote_value,
          user_id: requested_user_id,
          votable_type: 'Question')

        create(:vote, votable_id: question_with_other_vote.id,
          value: vote_value,
          user_id: other_user_id,
          votable_type: 'Question')
      end

      describe 'right vote values according to requested user' do
        subject { json }

        let(:params) { super().merge(id: question_id) }

        before { get :show, params: }

        context 'question_voted_by_user' do
          let(:question_id) { question_voted_by_user.id }

          describe "['vote_value_for_requested_user']" do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq vote_value }
          end
        end

        context 'question_not_voted_by_user_but_others' do
          let(:question_id) { question_with_other_vote.id }

          describe "['vote_value_for_requested_user']" do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq 0 }
          end
        end

        context 'question_not_voted' do
          let(:question_id) { question.id }

          describe "['vote_value_for_requested_user']" do
            subject { super()['vote_value_for_requested_user'] }

            it { is_expected.to eq 0 }
          end
        end
      end
    end

    describe 'read state for user' do
      let(:action) { get :show, params: }
      let(:params) { {id: question.id} }

      it 'does not have a read state' do
        action
        expect(json).not_to include('read')
      end

      context 'with watch_for_user_id' do
        let(:params) { super().merge!(watch_for_user_id: question.user_id) }

        it 'has a read state' do
          action
          expect(json).to include('read')
        end

        it 'is not read' do
          action
          expect(json['read']).to be_falsy
        end

        context 'with watch' do
          before { create(:watch, question_id: question.id, user_id: question.user_id) }

          it 'is read' do
            action
            expect(json['read']).to be true
          end
        end
      end
    end

    describe 'view count' do
      subject { action; json }

      let(:action) { get :show, params: }
      let(:params) { {id: question.id} }

      describe "['views']" do
        subject { super()['views'] }

        it { is_expected.to be 0 }
      end

      context 'with watch' do
        before { create(:watch, question_id: question.id) }

        describe "['views']" do
          subject { super()['views'] }

          it { is_expected.to be 1 }
        end
      end
    end

    context 'with deleted question' do
      it 'responds with 404 Not Found' do
        get :show, params: {id: deleted_question.id}
        expect(response).to have_http_status :not_found
      end

      context 'with deleted flag' do
        it 'responds with question' do
          get :show, params: {id: deleted_question.id, deleted: true}
          expect(json['deleted']).to be_truthy
        end
      end
    end
  end

  describe 'POST create' do
    subject(:creation) { post :create, params: }

    let!(:sql_tag) { create(:sql_tag) }
    let(:definition_tag_attributes) { attributes_for(:definition_tag) }
    let(:tag_names) { [sql_tag.name] }
    let(:question_params) { attributes_for(:question) }
    let(:params) do
      question_params.merge(
        tag_names:,
        question_url: 'http://test.host/courses/test/question/{id}'
      )
    end

    before do
      Stub.service(
        :notification,
        events_url: '/events'
      )
      Stub.request(
        :notification, :post, '/events'
      ).to_return Stub.response(status: 201)
      Stub.service(
        :course,
        course_url: '/courses/{id}',
        section_url: '/sections/{id}'
      )
      Stub.request(
        :course, :get, "/courses/#{params[:course_id]}"
      ).to_return Stub.json({
        id: params[:course_id],
        title: 'My course',
        course_code: 'my_course',
        forum_is_locked: false,
      })

      Stub.service(
        :account,
        user_url: '/users/{id}'
      )
      Stub.request(
        :account, :get, "/users/#{question_params[:user_id]}"
      ).to_return Stub.json({
        id: question_params[:user_id],
        name: 'Egon Olsen',
      })
    end

    it { is_expected.to have_http_status :created }

    it 'creates a question on create' do
      expect { creation }.to change(Question, :count).by(1)
    end

    context 'with non-existent tag' do
      let(:tag_names) { [definition_tag_attributes[:name]] }

      it 'creates a tag with the question' do
        expect { creation }.to change(Tag, :count).by(1)
      end
    end

    context 'with image references' do
      let(:question) { nil }
      let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
      let(:question_params) { super().merge text: }
      let(:cid) { UUID4(question_params[:course_id]).to_s(format: :base62) }

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
        expect { creation }.to change(Question, :count).from(0).to(1)
        expect(Question.first.text).to include 's3://xikolo-pinboard'
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

        expect { creation }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq text: ['rtfile_rejected']
        end
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

        expect { creation }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq text: ['rtfile_error']
        end
      end
    end

    context 'with attachment upload' do
      let(:question) { nil }
      let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
      let(:question_params) { super().merge attachment_upload_id: upload_id }
      let(:cid) { UUID4(question_params[:course_id]).to_s(format: :base62) }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg'
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          'prefix=uploads%2F83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa')
          .to_return(
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

        expect { creation }.to change(Question, :count).from(0).to(1)
        expect(store_stub).to have_been_requested
        expect(Question.last.attachment_uri).not_to be_nil
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

        expect { creation }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq attachment_upload_id: ['invalid upload']
        end
      end

      it 'handles S3 errors during upload validating' do
        stub_request(:head, file_url).to_return(
          status: 403
        )
        expect { creation }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq attachment_upload_id: ['could not process file upload']
        end
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

        expect { creation }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq attachment_upload_id: ['could not process file upload']
        end
      end
    end

    context 'with implicit tags' do
      let(:section_tag) { create(:section_tag) }
      let(:implicit_tags) { [section_tag.id] }

      let(:params) { super().merge(implicit_tags:) }

      before do
        Stub.request(
          :course, :get, "/sections/#{section_tag.name}"
        ).to_return Stub.json({
          id: section_tag.name,
          pinboard_closed: false,
        })
      end

      it 'creates a question with the section tag' do
        expect do
          creation
        end.to change(Question, :count).from(1).to(2)
        expect(Question.order(created_at: :desc).first.tags.map(&:id)).to include section_tag.id
      end

      context 'with a non-existent tag name' do
        let(:tag_names) { ['Sample Tag'] }

        it 'creates a tag with the question' do
          expect { creation }.to change(ExplicitTag, :count).by(1)
        end
      end
    end

    it 'creates a subscription with the question' do
      expect { creation }.to change(Subscription, :count).by(1)
    end

    it 'answers with question' do
      creation

      expect(json['text']).not_to be_nil
      expect(json['text']).to eq(attributes_for(:question)[:text])
    end

    context 'with a supplied learning_room_id' do
      let(:learning_room_id) { '00000001-ffff-4444-9999-000000000003' }
      let(:question_params) { super().merge(learning_room_id:) }

      before do
        Stub.service(
          :collabspace,
          collab_space_url: '/collab_spaces/{id}'
        )

        Stub.request(
          :collabspace, :get, "/collab_spaces/#{learning_room_id}"
        ).to_return Stub.json({
          id: learning_room_id,
          name: 'My own collab space',
        })
      end

      it 'sets the course_id' do
        creation
        expect(json['course_id']).to eq question_params[:course_id]
      end

      it 'sets the learning_room_id' do
        creation
        expect(json['learning_room_id']).to eq '00000001-ffff-4444-9999-000000000003'
      end

      context 'with image references' do
        let(:question) { nil }
        let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
        let(:question_params) { super().merge text: }
        let(:cid) { UUID4(question_params[:course_id]).to_s(format: :base62) }
        let(:lid) { UUID4(learning_room_id).to_s(format: :base62) }

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
                           /courses/#{cid}/collabspaces/#{lid}
                           /topics/[0-9a-zA-Z]+/[0-9a-zA-Z]+/foo.jpg}x
          stub_request(:head, store_regex).and_return(status: 404)
          stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
          expect { creation }.to change(Question, :count).from(0).to(1)
          expect(Question.first.text).to include 's3://xikolo-pinboard'
        end
      end
    end

    # learning_room_id is an empty string if you just put it into forms
    # as a hidden field if it's not in the learning_room context
    context 'if the learning_room_id is an empty string' do
      let(:question_params) { super().merge(learning_room_id: '') }

      it 'sets the course_id' do
        creation
        expect(json['course_id']).to eq question_params[:course_id]
      end
    end

    context 'with an empty string as learning_room_id and tags' do
      # data from real app data
      let(:params) do
        {
          tags: ['Toloo'],
          text: 'asd',
          title: 'Abc',
          user_id: '00000001-3100-4444-9999-000000000001',
          course_id: '00000001-3300-4444-9999-000000000003',
          discussion_flag: '0',
          learning_room_id: '',
        }
      end

      it { is_expected.to be_successful }
    end

    it 'creates a watch for the question and its author' do
      expect { creation }.to change(Watch, :count).from(0).to(1)
    end

    context 'with duplicates' do
      subject(:creation) { post :create, params: question_params }

      before { create(:question, question_params) }

      it { is_expected.to have_http_status :unprocessable_entity }

      it 'does not create a Question' do
        expect { creation }.not_to change(Question, :count)
      end
    end

    it 'sends events for created objects' do
      expect(Msgr).to receive(:publish).with(
        anything,
        to: 'xikolo.pinboard.question.create'
      )
      expect(Msgr).to receive(:publish).with(
        anything,
        to: 'xikolo.pinboard.subscription.create'
      )
      expect(Msgr).to receive(:publish).with(
        anything,
        to: 'xikolo.pinboard.watch.create'
      )

      creation
    end
  end

  describe "PUT 'update'" do
    subject(:updated) { question.reload }

    let!(:question) { create(:question, tags: [sql_tag, section_tag, video_item_tag]) }
    let(:sql_tag) { create(:sql_tag) }
    let(:section_tag) { create(:section_tag) }
    let(:video_item_tag) { create(:video_item_tag) }

    let(:attributes) { attributes_for(:question) }
    let(:additional_params) { {title: 'Juchuuu'} }
    let(:implicit_tags) { nil }
    let(:request) { put :update, params: }
    let(:params) do
      attributes.merge(
        id: question.id,
        tag_names: [sql_tag.name, attributes_for(:offtopic_tag)[:name]]
      ).merge(additional_params)
    end

    it 'responds with 204 No Content' do
      request
      expect(response).to have_http_status :no_content
    end

    it 'changes the title' do
      request
      expect(updated.title).to eq 'Juchuuu'
    end

    context 'with image references' do
      subject(:modification) { request }

      let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
      let(:attributes) { super().merge text: }
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
        expect { modification; question.reload }.to change(question, :text)
        expect(question.text).to include 's3://xikolo-pinboard'
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
      let(:params) { super().merge attachment_upload_id: upload_id }
      let(:cid) { UUID4(question.course_id).to_s(format: :base62) }
      let(:file_url) do
        'https://s3.xikolo.de/xikolo-uploads/' \
          'uploads/83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa/image.jpg'
      end

      before do
        stub_request(:get,
          'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
          'prefix=uploads%2F83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa')
          .to_return(
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

        expect { request; question.reload }.to change(question, :attachment_uri)
        expect(store_stub).to have_been_requested
      end

      it 'removes an old attachment' do
        question.update attachment_uri: 's3://xikolo-pinboard/courses/1/threads/1/1/otto.jpg'
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

        expect { request; question.reload }.to change(question, :attachment_uri)
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

    it 'does not change the implicit tags' do
      request

      implicit_tag_names = updated.implicit_tags.map(&:name)
      expect(implicit_tag_names).to contain_exactly(section_tag.name, video_item_tag.name)
    end

    it 'adds a new explicit tag' do
      request

      explicit_tag_names = updated.explicit_tags.map(&:name)
      expect(explicit_tag_names).to contain_exactly(sql_tag.name, attributes_for(:offtopic_tag)[:name])
    end

    describe 'with an Answer' do
      subject(:updated) { question.reload }

      let!(:answer) { create(:answer) }
      let(:additional_params) { {accepted_answer_id: answer.id} }
      let(:question) { answer.question }

      it 'sets the accepted answer_id' do
        request
        expect(updated.accepted_answer_id).to eq answer.id
      end

      it 'can also change the accepted answer' do
        other_answer = Answer.create(question:)
        question.accepted_answer = other_answer
        question.save
        request
        expect(updated.accepted_answer_id).to eq answer.id
      end

      context 'when the question is tagged' do
        let(:params) { {id: question.id, accepted_answer_id: answer.id, text: question.text} }

        before do
          question.tags << create(:explicit_tag, name: 'custom_tag')
        end

        # REGRESSION TEST: Previously, sending only selected attributes (such
        # as accepted_answer_id) would reset explicit tags.
        it 'keeps explicit tags when marking an answer as accepted' do
          expect { request }.not_to change { question.explicit_tags.count }
          expect(question.reload.accepted_answer_id).to eq answer.id
        end
      end
    end

    describe 'for implicit tags' do
      context 'with no implicit tags' do
        let(:params) { super().merge(implicit_tags: ['']) }

        it 'removes the implicit tags' do
          request
          expect(updated.implicit_tags).to be_empty
        end
      end

      context 'with a new implicit tags' do
        let(:implicit_tag) { create(:technical_issues_tag) }
        let(:params) { super().merge(implicit_tags: [implicit_tag.id]) }

        it 'sets an implicit tag' do
          request
          expect(updated.implicit_tags.size).to eq(1)
        end

        it 'sets the correct implicit tag' do
          request
          expect(updated.implicit_tags.first.id).to eq implicit_tag.id
        end
      end
    end
  end

  describe "DELETE 'destroy'" do
    subject(:deleted) { question.reload }

    let!(:question) { create(:question_with_implicit_tags) }
    let(:request) { delete :destroy, params: {id: question.id} }

    it 'responds with 204 No Content' do
      request
      expect(response).to have_http_status :no_content
    end

    it 'changes the deleted flag to true' do
      request
      expect(deleted.deleted).to be_truthy
    end

    it 'does not delete the question record' do
      expect { request }.not_to change(Question, :count)
    end
  end
end

def json_reloaded
  # I couldn't think of a better way to reevaluate the let(:json)
  JSON.parse response.body
end
