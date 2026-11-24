# frozen_string_literal: true

require 'spec_helper'

describe QuizService::QuizzesController, type: :controller do
  include_context 'quiz_service API controller'

  let(:quiz) { create(:'quiz_service/quiz') }
  let(:params) { attributes_for(:'quiz_service/quiz') }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

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
          decorated_quiz = QuizService::QuizDecorator.new(create(:'quiz_service/quiz'))
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
        let(:bonus_quizzes) { create_list(:'quiz_service/quiz', 3) }
        let(:main_quizzes)  { create_list(:'quiz_service/quiz', 4) }
        let(:selftests)     { create_list(:'quiz_service/quiz', 5) }
        let(:course_id_filter_quizzes) { create_list(:'quiz_service/quiz', 6) }

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
              query: {content_type: 'QuizService::Quiz', course_id:}
            ).to_return Stub.json(course_item_ids.each_with_index.map do |item_id, i|
              {id: item_id, content_type: 'QuizService::Quiz', content_id: quiz_ids[i]}
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
      it { is_expected.to eq QuizService::QuizDecorator.new(quiz).as_json(api_version: 1).stringify_keys }
    end
  end

  describe '#update' do
    subject(:action) { put :update, params: params.merge(id: quiz.id) }

    let(:params) { attributes_for(:'quiz_service/quiz', time_limit_seconds: 4242) }

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
    let(:quiz) { create(:'quiz_service/quiz', time_limit_seconds: 5000, allowed_attempts: 4) }

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
        quiz = create(:'quiz_service/quiz', time_limit_seconds: 5000)
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
        quiz = create(:'quiz_service/quiz', allowed_attempts: 5)
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
