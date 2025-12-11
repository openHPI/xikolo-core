# frozen_string_literal: true

module QuizService
class EssayQuestionStats < QuestionStatistics # rubocop:disable Layout/IndentationWidth
  def all
    super.merge(answers: text_answer_stats)
  end

  private

  def text_answer_stats
    {avg_length: answer_stats.first['avg_length'].to_f}
  end

  def answer_stats_query
    <<~SQL.squish
         SELECT AVG(LENGTH(quiz_submission_answers.user_answer_text)) AS avg_length
           FROM quiz_submission_questions
      LEFT JOIN quiz_submission_answers
             ON quiz_submission_answers.quiz_submission_question_id = quiz_submission_questions.id
          WHERE quiz_submission_questions.quiz_question_id = '#{question_id}'
            AND quiz_submission_answers.user_answer_text IS NOT NULL
    SQL
  end

  def answer_stats
    @answer_stats ||=
      ActiveRecord::Base.connection.execute(answer_stats_query)
  end
end
end
