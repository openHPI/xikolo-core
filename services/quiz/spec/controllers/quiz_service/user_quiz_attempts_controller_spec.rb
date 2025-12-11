# frozen_string_literal: true

require 'spec_helper'

describe QuizService::UserQuizAttemptsController, type: :controller do
  include_context 'quiz_service API controller'

  let!(:quiz_submission) { create(:'quiz_service/quiz_submission', :submitted) }
  let(:json) { JSON.parse response.body }

  describe '#show' do
    subject(:request) { get :show, params: }

    context 'without params' do
      let(:params) { {} }

      it 'fails and responds with 422 Unprocessable Entity' do
        request
        expect(response).to have_http_status :unprocessable_content
      end
    end

    context 'with valid params' do
      let(:params) do
        {user_id: quiz_submission.user_id, quiz_id: quiz_submission.quiz_id, format: :json}
      end

      it 'answers with a single user attempt object' do
        request
        expect(response).to have_http_status :ok
        expect(json).to eq({
          'user_id' => quiz_submission.user_id,
          'quiz_id' => quiz_submission.quiz_id,
          'attempts' => 1,
          'additional_attempts' => 0,
        })
      end
    end
  end

  describe '#create' do
    subject(:request) { post :create, params: }

    let(:params) do
      {
        user_id: quiz_submission.user_id,
        quiz_id: quiz_submission.quiz_id,
        additional_attempts: 2,
      }
    end

    # The response is always 200 although this action
    # EITHER creates or updates resource
    it 'responds with 204 No Content' do
      request
      expect(response).to have_http_status :no_content
    end

    it 'creates a new quiz attempt' do
      expect { request }.to change(QuizService::AdditionalQuizAttempt, :count).from(0).to(1)
    end

    context 'with faulty user or quiz IDs' do
      let(:params) { super().merge(user_id: 'klaus', quiz_id: 'karl') }

      it 'only accepts UUIDs for quiz_id, user_id' do
        request
        expect(response).to have_http_status :bad_request
      end
    end

    context 'with faulty attempts value' do
      let(:params) { super().merge(additional_attempts: 'karl') }

      it 'only accepts integers for attempts' do
        request
        expect(response).to have_http_status :bad_request
      end
    end

    context 'with existing additional quiz attempts' do
      let!(:existing_attempts) do
        create(:'quiz_service/additional_quiz_attempt',
          user_id: quiz_submission.user_id,
          quiz_id: quiz_submission.quiz_id)
      end

      let(:params) { super().merge additional_attempts: 3 }

      it 'does not create a new quiz attempt' do
        expect { request }.not_to change(QuizService::AdditionalQuizAttempt, :count)
      end

      it 'updates the existing quiz attempts' do
        expect { request }.to change { existing_attempts.reload.count }.from(2).to(3)
      end
    end

    context 'with course ID' do
      let(:course_id) { generate(:course_id) }
      let(:params) { super().except(:quiz_id).merge(course_id:) }

      before { Sidekiq::Testing.fake! }

      it 'schedules a job to unlock the assignments' do
        expect { request }.to change(QuizService::UnlockCourseAssignmentsWorker.jobs, :size).by(1)
      end

      it 'responds with 202 Accepted' do
        request
        expect(response).to have_http_status :accepted
      end
    end
  end
end
