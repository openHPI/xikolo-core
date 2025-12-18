# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz Submissions: Create', type: :request do
  subject(:creation) { api.rel(:quiz_submissions).post(payload).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }

  let!(:quiz) { create(:'quiz_service/quiz') }
  let(:payload) do
    {
      quiz_id: quiz.id,
      user_id:,
      course_id: generate(:course_id),
    }
  end
  let(:user_id) { generate(:user_id) }

  it { is_expected.to respond_with :created }

  it 'creates a new quiz submission' do
    expect { creation }.to change { QuizService::QuizSubmission.where(quiz_id: quiz.id).count }.from(0).to(1)
  end

  it 'stores the passed course ID' do
    creation
    expect(QuizService::QuizSubmission.first.course_id).to eq payload[:course_id]
  end

  context 'for a quiz with limited attempts' do
    let!(:quiz) { create(:'quiz_service/quiz', allowed_attempts: 1) }

    context 'when another submission was already submitted' do
      before { create(:'quiz_service/quiz_submission', :submitted, quiz:, user_id:) }

      it 'responds with 422 Unprocessable Entity' do
        expect { creation }.to raise_error(Restify::UnprocessableEntity)

        # No new submission should have been created
        expect(QuizService::QuizSubmission.where(quiz_id: quiz.id).count).to eq 1
      end
    end

    context 'when another submission has been created, but not yet submitted' do
      before { create(:'quiz_service/quiz_submission', quiz:, user_id:, created_at: 20.minutes.ago) }

      # This lets the frontend differentiate between existing submissions and
      # the limit of attempts being reached
      it { is_expected.to respond_with :ok }
    end
  end

  describe 'vendor data' do
    context 'nil' do
      let(:payload) { super().merge(vendor_data: nil) }

      it 'creates a new quiz submission' do
        expect { creation }.to change { QuizService::QuizSubmission.where(quiz_id: quiz.id).count }.from(0).to(1)

        expect(QuizService::QuizSubmission.find_by(quiz_id: quiz.id).vendor_data).to eq({})
      end
    end

    context 'with proctoring flag' do
      let(:payload) { super().merge(vendor_data: {proctoring: 'smowl_v2'}) }

      it 'creates a new quiz submission' do
        expect { creation }.to change { QuizService::QuizSubmission.where(quiz_id: quiz.id).count }.from(0).to(1)

        expect(QuizService::QuizSubmission.find_by(quiz_id: quiz.id).vendor_data).to eq({
          'proctoring' => 'smowl_v2',
        })
      end
    end
  end
end
