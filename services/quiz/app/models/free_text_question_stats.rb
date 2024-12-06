# frozen_string_literal: true

class FreeTextQuestionStats < QuestionStatistics
  def all
    super.merge(answers: text_answer_stats)
  end

  private

  def text_answer_stats
    {
      unique_answer_count:
        unique_answer_count_stats.first['unique_answer_count'],
      non_unique_answer_texts:
        parse_non_unique_answer_texts,
    }
  end

  def parse_non_unique_answer_texts
    non_unique_answer_texts =
      non_unique_answer_texts_stats.first['non_unique_answer_texts']

    return unless non_unique_answer_texts

    JSON.parse(non_unique_answer_texts)
  end

  def unique_answer_count_stats_query
    <<~SQL.squish
      SELECT COUNT(*) AS unique_answer_count
        FROM (
                   SELECT quiz_submission_answers.user_answer_text
                     FROM quiz_answers
                LEFT JOIN quiz_submission_answers
                       ON quiz_submission_answers.quiz_answer_id = quiz_answers.id
                    WHERE quiz_answers.question_id = '#{question.id}'
                      AND quiz_submission_answers.user_answer_text IS NOT NULL
                 GROUP BY quiz_submission_answers.user_answer_text
                   HAVING COUNT(quiz_submission_answers.user_answer_text) = 1
             ) AS unique_answer_texts
    SQL
  end

  def non_unique_answer_texts_stats
    @non_unique_answer_texts_stats ||=
      ActiveRecord::Base.connection.execute(non_unique_answer_texts_stats_query)
  end

  def non_unique_answer_texts_stats_query
    <<~SQL.squish
      SELECT json_object_agg(user_answer_text, answer_counts) AS non_unique_answer_texts
        FROM (
                  SELECT quiz_submission_answers.user_answer_text, COUNT(*) as answer_counts
                    FROM quiz_answers
               LEFT JOIN quiz_submission_answers
                      ON quiz_submission_answers.quiz_answer_id = quiz_answers.id
                   WHERE quiz_answers.question_id = '#{question.id}'
                     AND quiz_submission_answers.user_answer_text IS NOT NULL
                GROUP BY quiz_submission_answers.user_answer_text
                  HAVING COUNT(quiz_submission_answers.user_answer_text) > 1
             ) AS row
    SQL
  end

  def unique_answer_count_stats
    @unique_answer_count_stats ||=
      ActiveRecord::Base.connection.execute(unique_answer_count_stats_query)
  end
end
