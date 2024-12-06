# frozen_string_literal: true

require 'spec_helper'

describe UpdateQuestionStatisticsWorker, type: :worker do
  subject(:worker) { described_class.new.perform question.id, 1.minute.from_now.to_s }

  let!(:quiz) { create(:quiz) }
  let!(:question) { create(:multiple_answer_question, quiz:) }
  let!(:correct_answer) { create(:answer, question:, correct: true) }
  let!(:wrong_answer) { create(:answer, question:, correct: false) }
  let!(:quiz_submission) { create(:quiz_submission, quiz:, quiz_submission_time: Time.zone.now) }

  context 'for new question' do
    before do
      quiz_submission_question = create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id, points: 10)
      create(:quiz_submission_selectable_answer, quiz_submission_question:, quiz_answer_id: correct_answer.id)
      create(:quiz_submission_selectable_answer, quiz_submission_question:, quiz_answer_id: wrong_answer.id)
    end

    it 'creates question statistics' do
      expect { worker }.to change(QuestionStatistics, :count).from(0).to(1)
    end

    it 'sets statistics correctly' do
      worker
      expect(question.statistics.attributes).to include(
        'question_position' => question.position,
        'question_type' => question.type,
        'max_points' => question.points,
        'submission_count' => 1,
        'avg_points' => 10.0,
        'correct_submission_count' => 1,
        'partly_correct_submission_count' => 0,
        'incorrect_submission_count' => 0
      )
    end
  end

  context 'for existing question' do
    let!(:statistics) { create(:question_statistics, question:) }

    before do
      quiz_submission_question = create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id, points: 10)
      create(:quiz_submission_selectable_answer, quiz_submission_question:, quiz_answer_id: correct_answer.id)
      another_quiz_submission = create(:quiz_submission, quiz:, quiz_submission_time: Time.zone.now)
      create(:quiz_submission_question, quiz_submission: another_quiz_submission, quiz_question_id: question.id, points: 2)
    end

    it 'finds question statistics' do
      expect { worker }.not_to change(QuestionStatistics, :count)
    end

    it 'calculates avg_points correctly' do
      expect { worker }.to change { statistics.reload[:avg_points] }.from(10.0).to(6.0)
    end

    it 'increments submission_count' do
      expect { worker }.to change { statistics.reload[:submission_count] }.from(1).to(2)
    end
  end

  context 'for multiple answer question' do
    let!(:question) { create(:multiple_answer_question, quiz:) }
    let!(:statistics) { create(:question_statistics, :for_multiple_answer_question, question:) }
    let!(:quiz_submission) { create(:quiz_submission, quiz:) }
    let!(:correct_answer) { create(:answer, question:, correct: true, position: 1, text: 'Right') }
    let!(:wrong_answer) { create(:answer, question:, correct: false, position: 2, text: 'Wrong') }
    let!(:another_correct_answer) { create(:answer, question:, correct: true, position: 3, text: 'Right') }

    before do
      create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id, points: 10)
      create(:quiz_submission_answer, quiz_answer_id: correct_answer.id)
      create(:quiz_submission_answer, quiz_answer_id: wrong_answer.id)
      create(:quiz_submission_answer, quiz_answer_id: another_correct_answer.id)
    end

    it 'returns the correct number of answers' do
      worker
      expect(statistics.reload[:answer_statistics].count).to eq 3
    end

    it 'returns correct answers with submissions count' do
      worker
      expect(statistics.reload[:answer_statistics][0]).to include(
        'id' => correct_answer.id,
        'text' => correct_answer.text,
        'position' => correct_answer.position,
        'submission_count' => 1
      )
    end

    it 'returns wrong answer with submissions count' do
      worker
      expect(statistics.reload[:answer_statistics][1]).to include(
        'id' => wrong_answer.id,
        'text' => wrong_answer.text,
        'position' => wrong_answer.position,
        'submission_count' => 1
      )
    end

    it 'returns another correct answer with submissions count' do
      worker
      expect(statistics.reload[:answer_statistics][2]).to include(
        'id' => another_correct_answer.id,
        'text' => another_correct_answer.text,
        'position' => another_correct_answer.position,
        'submission_count' => 1
      )
    end
  end

  context 'for multiple choice question' do
    let!(:question) { create(:multiple_choice_question, quiz:) }
    let!(:statistics) { create(:question_statistics, :for_multiple_choice_question, question:) }
    let!(:quiz_submission) { create(:quiz_submission, quiz:) }
    let!(:correct_answer) { create(:answer, question:, correct: true, position: 1, text: 'Right') }
    let!(:wrong_answer) { create(:answer, question:, correct: false, position: 2, text: 'Wrong') }

    before do
      create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id, points: 10)
      create(:quiz_submission_answer, quiz_answer_id: correct_answer.id)
    end

    it 'retuns the correct numder of answers' do
      worker
      expect(statistics.reload[:answer_statistics].count).to eq 2
    end

    it 'returns correct answer with submissions count' do
      worker
      expect(statistics.reload[:answer_statistics][0]).to include(
        'id' => correct_answer.id,
        'text' => correct_answer.text,
        'position' => correct_answer.position,
        'submission_count' => 1
      )
    end

    it 'returns wrong answer with submissions count' do
      worker
      expect(statistics.reload[:answer_statistics][1]).to include(
        'id' => wrong_answer.id,
        'text' => wrong_answer.text,
        'position' => wrong_answer.position,
        'submission_count' => 0
      )
    end
  end

  context 'for free text question' do
    let!(:question) { create(:free_text_question, quiz:) }
    let!(:statistics) { create(:question_statistics, :for_free_text_question, question:) }
    let!(:answer) { create(:free_text_answer, question:) }

    before do
      create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id)
      create(:quiz_submission_free_text_answer, quiz_answer_id: answer.id, user_answer_text: 'Foo')
      create(:quiz_submission_free_text_answer, user_answer_text: 'Foo', quiz_answer_id: answer.id)
      create(:quiz_submission_free_text_answer, user_answer_text: 'teachbase', quiz_answer_id: answer.id)
    end

    it 'counts unique answers correctly' do
      expect { worker }.to change { statistics.reload[:answer_statistics]['unique_answer_count'] }.from(0).to(1)
    end

    it 'counts non unique answers correctly' do
      expect { worker }.to change { statistics.reload[:answer_statistics]['non_unique_answer_texts'] }.from(0).to('Foo' => 2)
    end
  end

  context 'for essay question' do
    let!(:question) { create(:essay_question, quiz:) }
    let!(:statistics) { create(:question_statistics, :for_essay_question, question:) }

    before do
      answer = create(:free_text_answer, question:)
      quiz_submission = create(:quiz_submission, quiz:)
      quiz_submission_question = create(:quiz_submission_question, quiz_submission:, quiz_question_id: question.id)
      create(:quiz_submission_free_text_answer, quiz_answer_id: answer.id, user_answer_text: 'Feedback should be long', quiz_submission_question_id: quiz_submission_question.id)
      create(:quiz_submission_free_text_answer, quiz_answer_id: answer.id, user_answer_text: 'Another Feedback', quiz_submission_question_id: quiz_submission_question.id)
    end

    it 'counts avg length correctly' do
      expect { worker }.to change { statistics.reload[:answer_statistics]['avg_length'] }.from(0).to(19.5)
    end
  end

  describe 'frequency of calculations' do
    subject(:worker) { described_class.new.perform question.id, 2.hours.ago.to_s }

    context 'when question statistics is newer than the time the worker was triggered' do
      let!(:statistics) { create(:question_statistics, question:, updated_at: 1.hour.ago) }

      it 'does not update question statistics' do
        expect { worker }.not_to change { statistics.reload.updated_at }
      end
    end

    context 'when question statistics is older than time the worker was triggered' do
      let!(:statistics) { create(:question_statistics, question:, updated_at: 3.hours.ago) }

      it 'updates question statistics' do
        expect { worker }.to change { statistics.reload.updated_at }
      end
    end
  end
end
