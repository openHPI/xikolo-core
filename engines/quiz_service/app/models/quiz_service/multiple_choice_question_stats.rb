# frozen_string_literal: true

module QuizService
class MultipleChoiceQuestionStats < QuestionStatistics # rubocop:disable Layout/IndentationWidth
  def all
    super.merge(answers: answer_stats)
  end

  private

  def answer_stats_query
    <<~SQL.squish
         SELECT quiz_answers.id AS id,
                quiz_answers.position AS position,
                quiz_answers.correct AS correct,
                quiz_answers.text AS text,
                COUNT(quiz_submission_answers.id) AS submission_count
           FROM quiz_answers
      LEFT JOIN quiz_submission_answers
             ON quiz_submission_answers.quiz_answer_id = quiz_answers.id
          WHERE quiz_answers.question_id = '#{question.id}'
       GROUP BY quiz_answers.id, quiz_answers.position, quiz_answers.correct, quiz_answers.text
       ORDER BY quiz_answers.position ASC
    SQL
  end

  def answer_stats
    @answer_stats ||=
      ActiveRecord::Base.connection.execute(answer_stats_query)
  end
end
end
