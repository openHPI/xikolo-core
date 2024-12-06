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

    context 'when the quiz has no points (can happen during editing)' do
      let(:quiz) { Xikolo::Quiz::Quiz.new(max_points: 0.0) }

      it 'gives zero percent' do
        expect(percentage).to eq 0
      end
    end
  end

  describe '#history_graph_data' do
    subject(:graph_data) { presenter.history_graph_data }

    let(:all_submissions) do
      [
        Xikolo::Submission::QuizSubmission.new(points: 3.0, quiz_submission_time: '2020-01-01T15:00:00.000Z'),
        Xikolo::Submission::QuizSubmission.new(points: 5.0, quiz_submission_time: '2020-01-03T08:00:00.000Z'),
      ]
    end

    it 'returns a hash mapping from submission time to number of points' do
      expect(graph_data).to eq(
        '2020-01-01T15:00:00.000+00:00' => 3.0,
        '2020-01-03T08:00:00.000+00:00' => 5.0
      )
    end
  end

  describe '#submission_labels' do
    subject(:labels) { presenter.submission_labels }

    let(:all_submissions) do
      [
        Xikolo::Submission::QuizSubmission.new(id: '81e01000-3800-4444-a001-000000000001', quiz_submission_time: '2020-01-01T15:00:00.000Z'),
        Xikolo::Submission::QuizSubmission.new(id: '81e01000-3800-4444-a001-000000000002', quiz_submission_time: '2020-01-03T08:00:00.000Z'),
      ]
    end

    it 'returns all submissions with date as label and the short UUID as value' do
      expect(labels).to eq [
        ['Wed, Jan 01, 2020 15:00:00', '3X4peD0bXdL9CIgkbC4mfD'],
        ['Fri, Jan 03, 2020 08:00:00', '3X4peD0bXdL9CIgkbC4mfE'],
      ]
    end
  end
end
