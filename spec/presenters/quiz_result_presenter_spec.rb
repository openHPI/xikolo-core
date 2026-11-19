# frozen_string_literal: true

require 'spec_helper'

describe QuizResultPresenter, type: :presenter do
  subject(:presenter) { described_class.new quiz, submission, all_submissions }

  let(:quiz) { Xikolo::Quiz::Quiz.new(max_points: 8.0) }
  let(:submission) { Xikolo::Submission::QuizSubmission.new(points: 7.0) }
  let(:all_submissions) { [submission] }

  describe '#percentage' do
    subject(:percentage) { presenter.percentage }

    it 'calculates the percentage correctly and rounds down' do
      expect(percentage).to eq 87
    end

    context 'with full points' do
      let(:submission) { Xikolo::Submission::QuizSubmission.new(points: 8.0) }

      it 'gives 100 percent' do
        expect(percentage).to eq 100
      end
    end

    context 'with a selected question-pool maximum' do
      let(:quiz) { Xikolo::Quiz::Quiz.new(max_points: 24.0) }
      let(:submission) { Xikolo::Submission::QuizSubmission.new(points: 7.0, max_points: 8.0) }

      it 'uses the selected questions maximum instead of the whole pool maximum' do
        expect(percentage).to eq 87
      end
    end

    context 'when the quiz has no points (can happen during editing)' do
      let(:quiz) { Xikolo::Quiz::Quiz.new(max_points: 0.0) }

      it 'gives zero percent' do
        expect(percentage).to eq 0
      end
    end
  end
end
