# frozen_string_literal: true

require 'spec_helper'

describe QuizzesController, type: :controller do
  let(:quiz) { create(:quiz) }
  let(:params) { attributes_for(:quiz) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  before do
    Stub.service(:course, build(:'course:root'))
  end

  describe '#index' do
    subject(:action) { get :index, params: }

    let(:params) { {} }

    it { is_expected.to be_successful }

    context 'with at least one quiz in database' do
      shared_examples_for 'an array as response containing at least one quiz' do
        subject { json }

        before { action }

        it { is_expected.to be_a Array }

        it 'first element should match the quiz decorator fields' do
          decorated_quiz = QuizDecorator.new(create(:quiz))
          decorated_json = decorated_quiz.as_json(api_version: 1)
          decorator_keys = decorated_json.stringify_keys.keys
          expect(json.first.keys).to match_array decorator_keys
        end
      end

      context 'with only one quiz in database' do
        before { quiz }

        it_behaves_like 'an array as response containing at least one quiz'
      end

      context 'with different quizzes in database' do
        let(:bonus_quizzes) { create_list(:quiz, 3) }
        let(:main_quizzes)  { create_list(:quiz, 4) }
        let(:selftests)     { create_list(:quiz, 5) }
        let(:course_id_filter_quizzes) { create_list(:quiz, 6) }

        before { bonus_quizzes; main_quizzes; selftests }

        shared_examples_for 'a correctly filtered response' do
          describe 'response' do
            subject { json }

            before { action }

            it { is_expected.to have(expected_item_count).items }

            it 'alls have the filtered value' do
              response_values = json.collect do |entry|
                entry.with_indifferent_access[filter_field]
              end
              expect(response_values.uniq).to eq [filter_value]
            end
          end
        end

        context 'with course_id filter set' do
          let(:course_id) { '00000001-3300-4444-9999-000000000001' }
          let(:params) { {course_id:} }
          let(:course_item_ids) do
            (1..3).collect do |i|
              format('00000003-3300-4444-9999-ffffffffff%02d', i)
            end
          end
          let(:quiz_ids) do
            (1..3).collect do |i|
              course_id_filter_quizzes[i].id
            end
          end

          before do
            Stub.request(
              :course, :get, '/items',
              query: {content_type: 'quiz', course_id:}
            ).to_return Stub.json(course_item_ids.each_with_index.map do |item_id, i|
              {id: item_id, content_type: 'quiz', content_id: quiz_ids[i]}
            end)
          end

          it 'answers with the quizzes that belong to a given course' do
            get(:index, params:)
            expect(json.pluck('id')).to match_array quiz_ids
          end
        end
      end
    end
  end

  describe '#show' do
    let(:action) { -> { get :show, params: {id: quiz.id} } }

    before { action.call }

    context 'response' do
      subject { response }

      its(:status) { is_expected.to eq 200 }
    end

    context 'json' do
      subject { json }

      it { is_expected.not_to eq quiz.as_json }
      it { is_expected.to eq QuizDecorator.new(quiz).as_json(api_version: 1).stringify_keys }
    end
  end

  describe 'create quiz by import from xml' do
    subject(:action) { -> { post :create, body: xml_params.to_json, as: :json } }

    let(:course_id) { '00000001-3300-4444-9999-000000000001' }
    let(:section_id) { '00000001-3300-4444-9999-000000000002' }
    let(:quiz_id) { '00000001-3300-4444-9999-000000000004' }
    let(:alternate_section_id) { '00000001-3300-4444-9999-000000000005' }
    let(:course_code) { 'mytest' }
    let(:xml_string) do
      <<~XML
        <?xml version="1.0" encoding="utf-8"?>

        <!-- multiple quizzes -->
        <quizzes>

          <!-- one question, multiple answers -->
          <quiz course_code="#{course_code}" section="1">
            <name lang="en">My 1st Test</name>
            <attempts>0</attempts>
            <time_limit>0</time_limit>
            <questions>
              <question points="3" type="FreeText">
                <text>My Question</text>
                <answers>
                  <answer correct="true" type="TextAnswer">
                    <text lang="en">My correct answer</text>
                  </answer>
                  <answer correct="false" type="TextAnswer">
                    <text lang="en">My false answer</text>
                  </answer>
                </answers>
              </question>
            </questions>
          </quiz>

          <!-- multiple questions, one answer each -->
          <quiz course_code="#{course_code}" section="1">
            <name lang="en">My 2nd Test</name>
            <attempts>0</attempts>
            <time_limit>0</time_limit>
            <questions>
              <question points="3" type="FreeText">
                <text>My 1st Question</text>
                <answers>
                  <answer correct="false" type="TextAnswer">
                    <text lang="en">My false answer</text>
                  </answer>
                </answers>
              </question>
              <question points="3" type="FreeText">
                <text>My 2nd Question</text>
                <answers>
                  <answer correct="true" type="TextAnswer">
                    <text lang="en">My false answer</text>
                  </answer>
                </answers>
              </question>
            </questions>
          </quiz>
        </quizzes>
      XML
    end

    let(:xml_params) do
      {
        course_code:,
        course_id:,
        xml: xml_string,
      }
    end

    let(:course_section_get_response) do
      Stub.json([{
        id: section_id,
        course_id:,
        title: 'Lecture 1',
      }])
    end

    before do
      Stub.request(
        :course, :get, '/sections', query: hash_including(
          course_id:
        )
      ).to_return(course_section_get_response)
      Stub.request(
        :course, :post, '/items', body: hash_including(
          title: /My 1st|2nd Test/,
          content_type: 'quiz',
          section_id:
        )
      ).to_return Stub.json({id: quiz_id})
      Stub.request(
        :course, :get, '/items', query: hash_including(content_id: anything)
      ).to_return Stub.json([{id: quiz_id}])
      Stub.request(
        :course, :patch, "/items/#{quiz_id}", body: hash_including(
          max_points: ->(v) { [6.0, 3.0].include?(v) }
        )
      )
      Stub.request(
        :course, :get, '/items',
        query: hash_including(section_id:)
      ).to_return Stub.json([])
    end

    context 'with a successful request' do
      it 'responds with 204 No Content' do
        action.call
        expect(response).to have_http_status :no_content
      end

      it 'creates a new quiz' do
        expect { action.call }.to change(Quiz, :count).from(0).to(2)
      end
    end

    context 'when no name is given' do
      let(:xml_string) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <quizzes>
            <quiz course_code="#{course_code}" section="1">
              <!-- the quiz name attribute is required -->
              <!-- <name lang="en">My Test</name> -->
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <questions>
                <question points="3" type="FreeText">
                  <text>My Question</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">My Answer</text>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
          </quizzes>
        XML
      end

      it 'responds with 422 Unprocessable Entity due to missing name' do
        action.call
        expect(response).to have_http_status :unprocessable_content
        expect(response.body).to eql "{\"errors\":[\"3:0: ERROR: Element 'quiz': Missing child element(s). Expected is one of ( name, instructions, due_date, publish_results_date ).\"]}"
      end
    end

    context 'when given section cannot be found' do
      let(:xml_string) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <quizzes>
            <quiz course_code="#{course_code}" section="5">
              <name lang="en">My Test</name>
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <questions>
                <question points="3" type="FreeText">
                  <text>My Question</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">My Answer</text>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
          </quizzes>
        XML
      end

      # if section cannot be found with given position,
      # course service returns an empty section list
      let(:course_section_get_response) { Stub.json([]) }

      it 'responds with 422 Unprocessable Entity due to missing section' do
        action.call
        expect(response).to have_http_status :unprocessable_content
        expect(response.body).to eql '{"errors":["Course section for quiz \'My Test\' does not exist"]}'
      end
    end

    context 'with success - preview only' do
      let(:xml_params) do
        {
          course_code:,
          course_id:,
          xml: xml_string,
          preview: true,
        }
      end

      let(:preview_response) do
        {
          params: xml_params,
          quizzes: [
            {
              'name' => 'My 1st Test',
              'external_ref' => nil,
              'section' => '1',
              'course_code' => 'mytest',
              'number_questions' => 1,
              'number_answers' => 2,
              'new_record' => true,
            },
            {
              'name' => 'My 2nd Test',
              'external_ref' => nil,
              'section' => '1',
              'course_code' => 'mytest',
              'number_questions' => 2,
              'number_answers' => 2,
              'new_record' => true,
            },
          ],
        }
      end

      it 'responds with 200 Ok - quizzes as hash and the given parameters' do
        action.call
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eql preview_response.as_json
      end
    end

    context 'with success - preview only, one quiz only' do
      let(:xml_string) do
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <quizzes>
            <quiz course_code="#{course_code}" section="1" subsection="1">
              <!-- the quiz name attribute is required -->
              <name lang="en">My Test</name>
              <attempts>0</attempts>
              <time_limit>0</time_limit>
              <questions>
                <question points="3" type="FreeText">
                  <text>My Question</text>
                  <answers>
                    <answer correct="true" type="TextAnswer">
                      <text lang="en">My Answer</text>
                    </answer>
                  </answers>
                </question>
              </questions>
            </quiz>
          </quizzes>
        XML
      end

      let(:xml_params) do
        {
          course_code:,
          course_id:,
          xml: xml_string,
          preview: true,
        }
      end

      let(:preview_response) do
        {
          params: xml_params,
          quizzes: [
            {
              'name' => 'My Test',
              'external_ref' => nil,
              'section' => '1',
              'subsection' => '1',
              'course_code' => 'mytest',
              'number_questions' => 1,
              'number_answers' => 1,
              'new_record' => true,
            },
          ],
        }
      end

      before do
        Stub.request(
          :course, :get, '/sections', query: hash_including(parent_id: section_id)
        ).to_return(Stub.json([{
          id: alternate_section_id,
          course_id:,
          title: 'Lecture 1.1',
        }]))
      end

      it 'responds with 200 Ok - with quizzes as hash and the given parameters' do
        action.call
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body)).to eql preview_response.as_json
      end
    end
  end

  describe '#update' do
    subject(:action) { put :update, params: params.merge(id: quiz.id) }

    let(:params) { attributes_for(:quiz, time_limit_seconds: 4242) }

    it 'responds with 204 No Content' do
      action
      expect(response).to have_http_status :no_content
    end

    context 'with invalid time_limit_seconds value' do
      let(:params) { super().merge(time_limit_seconds: -1) }

      it 'responds with 422 Unprocessable Entity' do
        action
        expect(response).to have_http_status :unprocessable_content
      end
    end

    context 'with invalid allowed_attempts value' do
      let(:params) { super().merge(allowed_attempts: 'One') }

      it 'responds with 422 Unprocessable Entity' do
        action
        expect(response).to have_http_status :unprocessable_content
      end
    end

    it 'applies new attributes' do
      expect { action }.to change { quiz.reload.time_limit_seconds }.from(quiz.time_limit_seconds).to(4242)
    end
  end

  describe 'with versioning', :versioning do
    let(:quiz) { create(:quiz, time_limit_seconds: 5000, allowed_attempts: 4) }

    it 'returns one version at the beginning' do
      expect(quiz.versions.size).to be 1
    end

    it 'returns two versions when modified' do
      put :update, params: {id: quiz.id, time_limit_seconds: 4000}
      quiz.reload
      expect(quiz.versions.size).to be 2
    end

    it 'answers with the previous version' do
      put :update, params: {id: quiz.id, time_limit_seconds: 4000}
      quiz.reload
      expect(quiz.time_limit_seconds).to eq 4000
      expect(quiz.paper_trail.previous_version.time_limit_seconds).to eq 5000
    end

    context 'with given timestamp' do
      # TODO: Move resources in let/before blocks
      it 'returns version of quiz at this time' do
        Timecop.travel(2008, 9, 1, 12, 0, 0)
        quiz = create(:quiz, time_limit_seconds: 5000)
        Timecop.travel(2010, 9, 1, 12, 0, 0)
        put :update, params: {id: quiz.id, time_limit_seconds: 4000}
        Timecop.return

        quiz.reload
        expect(quiz.time_limit_seconds).to eq 4000
        params = {id: quiz.id, version_at: DateTime.new(2009, 9, 1, 12, 0, 0).to_s}
        get(:show, params:)
        expect(json['time_limit_seconds']).to eq 5000
      end

      it 'returns newest allowed_attempts attribute' do
        Timecop.travel(2008, 9, 1, 12, 0, 0)
        quiz = create(:quiz, allowed_attempts: 5)
        Timecop.travel(2010, 9, 1, 12, 0, 0)
        put :update, params: {id: quiz.id, allowed_attempts: 4}
        Timecop.return

        quiz.reload
        expect(quiz.allowed_attempts).to eq 4
        expect(quiz.current_allowed_attempts).to eq 4
        params = {id: quiz.id, version_at: DateTime.new(2009, 9, 1, 12, 0, 0).to_s}
        get(:show, params:)
        expect(json['allowed_attempts']).to eq 5
        expect(json['current_allowed_attempts']).to eq 4
      end
    end
  end
end
