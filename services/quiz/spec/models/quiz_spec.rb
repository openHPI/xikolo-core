# frozen_string_literal: true

require 'spec_helper'

describe Quiz, type: :model do
  subject(:quiz) do
    Quiz.create(
      time_limit_seconds: 3600,
      unlimited_time: false,
      allowed_attempts: 1,
      unlimited_attempts: false
    )
  end

  it { is_expected.to accept_values_for(:time_limit_seconds, '3600') }
  it { is_expected.to accept_values_for(:allowed_attempts, '1') }

  describe '#attempt!' do
    subject(:attempt) { quiz.attempt!(user_id) }

    let(:user_id) { generate(:user_id) }

    context 'when there is a submitted submission for the user' do
      let!(:existing_submission) { create(:quiz_submission, :submitted, quiz:, user_id:) }

      context 'for a quiz with unlimited attempts' do
        before { quiz.update(unlimited_attempts: true) }

        it 'returns a new quiz submission' do
          expect(attempt).to be_a QuizSubmission
          expect(attempt).not_to eq existing_submission
          expect(attempt.user_id).to eq user_id
          expect(attempt.quiz_id).to eq quiz.id
        end

        context 'when called with additional parameters' do
          subject(:attempt) { quiz.attempt!(user_id, course_id:) }

          let(:course_id) { generate(:course_id) }

          it 'stores these parameters on the new submission' do
            expect(attempt.course_id).to eq course_id
          end
        end
      end

      context 'for a quiz with just one attempt' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 1) }

        it 'returns an invalid quiz submission' do
          expect(attempt).to be_a QuizSubmission
          expect(attempt.errors.added?(:base, 'no_attempts_left')).to be true
        end

        context 'when the user was granted an additional attempt' do
          before { create(:additional_quiz_attempt, quiz_id: quiz.id, user_id:) }

          it 'returns a new quiz submission' do
            expect(attempt).to be_a QuizSubmission
            expect(attempt).not_to eq existing_submission
            expect(attempt.user_id).to eq user_id
            expect(attempt.quiz_id).to eq quiz.id
          end
        end
      end

      context 'for a quiz with multiple attempts' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 2) }

        it 'returns a new quiz submission' do
          expect(attempt).to be_a QuizSubmission
          expect(attempt).not_to eq existing_submission
          expect(attempt.user_id).to eq user_id
          expect(attempt.quiz_id).to eq quiz.id
        end
      end
    end

    context 'when the user has an unsubmitted submission that can still be submitted' do
      let!(:existing_submission) { create(:quiz_submission, quiz:, user_id:, created_at: 1.hour.ago) }

      before { quiz.update(unlimited_time: false, time_limit_seconds: 2.hours.to_i) }

      context 'for a quiz with unlimited attempts' do
        before { quiz.update(unlimited_attempts: true) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end

      context 'for a quiz with just one attempt' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 1) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end

      context 'for a quiz with multiple attempts' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 2) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end
    end

    context 'when the user has an unsubmitted submission that is beyond deadline' do
      let!(:existing_submission) { create(:quiz_submission, quiz:, user_id:, created_at: 1.hour.ago) }

      before { quiz.update(unlimited_time: false, time_limit_seconds: 30.minutes.to_i) }

      context 'for a quiz with unlimited attempts' do
        before { quiz.update(unlimited_attempts: true) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end

      context 'for a quiz with just one attempt' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 1) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end

      context 'for a quiz with multiple attempts' do
        before { quiz.update(unlimited_attempts: false, allowed_attempts: 2) }

        it 'returns the existing quiz submission' do
          expect(attempt).to eq existing_submission
        end
      end
    end
  end

  describe 'with versioning', :versioning do
    subject do
      Quiz.first.paper_trail.version_at DateTime.new(2009, 1, 1, 12, 0, 0).to_s
    end

    before do
      Timecop.travel 2008, 1, 1, 12, 0, 0
      quiz
      Timecop.travel 2010, 1, 1, 12, 0, 0
      quiz.update(
        time_limit_seconds: 400,
        unlimited_time:     true,
        allowed_attempts:   5,
        unlimited_attempts: true
      )
      Timecop.return
    end

    its(:time_limit_seconds) { is_expected.to eq 3600 }
    its(:current_time_limit_seconds) { is_expected.to eq 400 }

    its(:allowed_attempts) { is_expected.to eq 1 }
    its(:current_allowed_attempts) { is_expected.to eq 5 }

    its(:unlimited_time) { is_expected.to be false }
    its(:current_unlimited_time) { is_expected.to be true }

    its(:unlimited_attempts) { is_expected.to be false }
    its(:current_unlimited_attempts) { is_expected.to be true }
  end
end
