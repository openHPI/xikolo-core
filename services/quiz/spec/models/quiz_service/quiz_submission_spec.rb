# frozen_string_literal: true

require 'spec_helper'

describe QuizService::QuizSubmission, type: :model do
  subject(:quiz_submission) { described_class.create params }

  let(:params) { {} }

  its(:quiz_access_time) { is_expected.to eq quiz_submission.created_at }

  context 'with quiz_submission_time set' do
    let(:params) { {quiz_submission_time: DateTime.now.in_time_zone} }

    its(:submitted) { is_expected.to be_truthy }
  end

  context 'without quiz_submission_time set' do
    let(:params) { {quiz_submission_time: nil} }

    its(:submitted) { is_expected.to be_falsey }
  end

  context 'with two questions' do
    let(:params) { {id: '00000000-0000-4444-8888-000000000001'} }

    before do
      create(:'quiz_service/quiz_submission_question', quiz_submission:)
      create(:'quiz_service/quiz_submission_question', quiz_submission:)
    end

    its(:question_count) { is_expected.to eq(2) }
    its(:points) { is_expected.to eq(4.0) }
  end

  context 'with floating points' do
    let(:params) { {id: '00000000-0000-4444-8888-000000000001'} }

    before do
      create(:'quiz_service/quiz_submission_question', quiz_submission:, points: Rational(4, 3))
      create(:'quiz_service/quiz_submission_question', quiz_submission:, points: Rational(4, 3))
    end

    it 'rounds points to one decimal' do
      expect(quiz_submission.points).to eq 2.7
    end
  end

  context 'without question' do
    its(:question_count) { is_expected.to eq(0) }
    its(:points) { is_expected.to eq(0) }
  end

  describe '(scopes)' do
    describe '#by_user' do
      subject(:scope) { described_class.by_user(user_id) }

      let(:user_id) { generate(:user_id) }

      before do
        quiz = create(:'quiz_service/quiz')
        create(:'quiz_service/quiz_submission', :submitted, quiz:, user_id:)
        create(:'quiz_service/quiz_submission', quiz:, user_id:)
        create(:'quiz_service/quiz_submission', user_id:)
        create(:'quiz_service/quiz_submission', quiz:, user_id: generate(:user_id))
      end

      it 'returns all submissions by that user' do
        expect(scope.map(&:user_id)).to eq [user_id, user_id, user_id]
      end
    end

    describe '#unsubmitted' do
      subject(:scope) { described_class.unsubmitted }

      before do
        quiz = create(:'quiz_service/quiz')
        create_list(:'quiz_service/quiz_submission', 2, quiz:)
        create_list(:'quiz_service/quiz_submission', 3, :submitted, quiz:)
      end

      it 'returns all unsubmitted submissions' do
        expect(scope.count).to eq 2
        expect(scope.any?(&:submitted)).to be false
      end
    end
  end
end
