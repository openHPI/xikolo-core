# frozen_string_literal: true

require 'spec_helper'

class QuizQuestionsHelperTestClass
  include QuizQuestionsHelper
end

describe QuizQuestionsHelper, type: :helper do
  subject(:status) do
    QuizQuestionsHelperTestClass.new.question_status(question, submission_question:)
  end

  let(:question_class) { Xikolo::Quiz::Question }
  let(:question) do
    double = instance_double(question_class, points: max_points)
    allow(double).to receive(:is_a?).and_return(question_class == Xikolo::Quiz::EssayQuestion)
    double
  end
  let(:submission_question) { instance_double(Xikolo::Submission::QuizSubmissionQuestion, points: earned_points) }
  let(:max_points) { 10.0 }
  let(:earned_points) { 10.0 }

  it 'is correct when the learner earned full points' do
    expect(status).to eq 'correct'
  end

  context 'when the learner earned fewer than full points' do
    let(:earned_points) { 3.0 }

    it 'is incorrect' do
      expect(status).to eq 'incorrect'
    end
  end

  context 'with a free text question (auto-graded)' do
    let(:question_class) { Xikolo::Quiz::FreeTextQuestion }

    it 'is correct when the learner earned full points' do
      expect(status).to eq 'correct'
    end

    context 'when the learner earned no points' do
      let(:earned_points) { 0.0 }

      it 'is incorrect' do
        expect(status).to eq 'incorrect'
      end
    end
  end

  context 'with an essay question (manually graded)' do
    let(:question_class) { Xikolo::Quiz::EssayQuestion }

    it 'returns nil' do
      expect(status).to be_nil
    end
  end

  context 'with a zero-point question' do
    let(:max_points) { 0.0 }
    let(:earned_points) { 0.0 }

    it 'returns nil' do
      expect(status).to be_nil
    end
  end

  context 'without a submission question' do
    let(:submission_question) { nil }

    it 'returns nil' do
      expect(status).to be_nil
    end
  end

  describe '#displayed_max_points' do
    subject(:helper) { QuizQuestionsHelperTestClass.new }

    let(:quiz) { instance_double(Xikolo::Quiz::Quiz, displayed_question_count:) }

    context 'with 10 displayed questions' do
      let(:displayed_question_count) { 10 }

      it 'returns 21 (3 easy + 3 mid + 4 hard)' do
        expect(helper.displayed_max_points(quiz)).to eq 21
      end
    end

    context 'with 20 displayed questions' do
      let(:displayed_question_count) { 20 }

      it 'returns 42' do
        expect(helper.displayed_max_points(quiz)).to eq 42
      end
    end

    context 'with 30 displayed questions' do
      let(:displayed_question_count) { 30 }

      it 'returns 63' do
        expect(helper.displayed_max_points(quiz)).to eq 63
      end
    end

    context 'with no displayed questions' do
      let(:displayed_question_count) { nil }

      it 'returns nil' do
        expect(helper.displayed_max_points(quiz)).to be_nil
      end
    end
  end
end
