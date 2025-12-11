# frozen_string_literal: true

module QuizService
class QuestionStatistics < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :question_statistics

  belongs_to :question

  validates :question_id, uniqueness: true

  def calculate!
    calculate

    save!
  end

  def calculate
    # question.stats.all initializes an instance of corresponding QuestionStatistics and calls
    # all method, which queries the database and calculates the stats
    statistic_data = question.stats.all

    self.question_type = statistic_data[:type]
    self.question_position = statistic_data[:position]
    self.question_text = statistic_data[:text]
    self.submission_user_count = statistic_data[:submission_user_count]
    self.submission_count = statistic_data[:submission_count]
    self.max_points = statistic_data[:max_points]
    self.avg_points = statistic_data[:avg_points]
    self.answer_statistics = statistic_data[:answers]

    self.correct_submission_count = statistic_data[:correct_submission_count]
    self.incorrect_submission_count = statistic_data[:incorrect_submission_count]
    self.partly_correct_submission_count = statistic_data[:partly_correct_submission_count]
  end

  def all
    {
      id: question.id,
      type: question.type,
      text: question.text,
      position: question.position,
      max_points: question.points,
      avg_points: stats['avg_points'],
      submission_count: stats['submission_count'],
      submission_user_count: stats['submission_user_count'],
      correct_submission_count: stats['correct_submissions'],
      incorrect_submission_count: stats['incorrect_submissions'],
      partly_correct_submission_count: stats['partly_correct_submissions'],
    }
  end

  protected

  def stats
    @stats ||= ActiveRecord::Base.connection.execute(stats_query).first
  end

  def stats_query
    <<~SQL.squish
         SELECT AVG(quiz_submission_questions.points) AS avg_points,
                COUNT(quiz_submission_questions.id) AS submission_count,
                COUNT(DISTINCT(quiz_submissions.user_id)) AS submission_user_count,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points = '#{question.points}'
                    THEN 1
                    ELSE NULL
                  END
                ) AS correct_submissions,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points = 0
                      AND quiz_submission_questions.points < '#{question.points}'
                    THEN 1
                    ELSE NULL
                  END
                ) AS incorrect_submissions,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points > 0
                      AND quiz_submission_questions.points < '#{question.points}'
                    THEN 1
                    ELSE NULL
                  END
                ) AS partly_correct_submissions
           FROM quiz_submission_questions
      LEFT JOIN quiz_submissions
             ON quiz_submissions.id = quiz_submission_questions.quiz_submission_id
          WHERE quiz_submission_questions.quiz_question_id = '#{question_id}'
            AND quiz_submissions.quiz_submission_time IS NOT NULL
    SQL
  end
end
end
