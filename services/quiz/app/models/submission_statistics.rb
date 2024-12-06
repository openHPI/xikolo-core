# frozen_string_literal: true

class SubmissionStatistics
  include Draper::Decoratable

  def initialize(quiz)
    @quiz = quiz
  end

  def total_submissions
    submissions.count
  end

  def total_submissions_distinct
    submissions.distinct.count(:user_id)
  end

  def max_points
    @quiz.max_points
  end

  def avg_points
    @quiz.avg_points
  end

  def unlimited_time
    @quiz.unlimited_time
  end

  def avg_submit_duration
    return 0 if submissions.count.zero?

    total_submit_duration = submissions.sum(
      'extract(epoch from age(quiz_submission_time, created_at))'
    )
    total_submit_duration.fdiv(submissions.count)
  end

  def submissions_over_time
    result = submissions.group_by_day(:quiz_submission_time).count

    if result.count <= 3
      # group by day after three days
      result = submissions.group_by_hour(:quiz_submission_time).count
    end

    result
  end

  # deprecated, remove when legacy usage is refactored
  # rubocop:disable Style/Next
  def questions
    result = []

    questions = QuizSubmissionQuestion.unscoped
      .select('quiz_question_id, avg(points), count(quiz_question_id)')
      .joins(:quiz_submission)
      .where(quiz_submissions: {quiz_id: @quiz.id})
      .group('quiz_question_id')
      .group_by(&:quiz_question_id)

    answers = QuizSubmissionQuestion.unscoped
      .select('quiz_question_id, quiz_submission_answers.quiz_answer_id, count(quiz_submission_answers.quiz_answer_id)')
      .joins(:quiz_submission_answers)
      .joins(:quiz_submission)
      .where(quiz_submissions: {quiz_id: @quiz.id})
      .group(%w[quiz_question_id quiz_submission_answers.quiz_answer_id])
      .group_by(&:quiz_answer_id)

    answer_texts = QuizSubmissionQuestion.unscoped
      .select('user_answer_text, quiz_question_id, quiz_submission_answers.quiz_answer_id, count(user_answer_text)')
      .joins(:quiz_submission_answers)
      .joins(:quiz_submission)
      .where(quiz_submissions: {quiz_id: @quiz.id})
      .where.not(quiz_submission_answers: {user_answer_text: nil})
      .group(%w[quiz_question_id quiz_submission_answers.quiz_answer_id quiz_submission_answers.user_answer_text])
      .group_by(&:quiz_answer_id)

    questions.each do |question|
      r = {}
      r[question[0]] = {}
      r[question[0]][:avg_points] = question[1][0].avg
      r[question[0]][:count] = question[1][0].count
      r[question[0]][:answers] = {}
      answers.each do |answer|
        id = answer[0]
        if answer[1][0].quiz_question_id == question[0]
          r[question[0]][:answers][id] = {}
          r[question[0]][:answers][id][:count] = answer[1][0].count
          r[question[0]][:answers][id][:list] = []
          answer_texts.each do |text_question|
            if id == text_question[0]
              text_question[1].each do |tq|
                obj = {}
                obj[:text] = tq.user_answer_text
                obj[:count] = tq.count
                r[question[0]][:answers][id][:list] << obj
              end
            end
          end
        end
      end
      result << r
    end

    result
  end
  # rubocop:enable all

  def questions_base_stats
    query = <<~SQL.squish
         SELECT quiz_questions.id AS id,
                quiz_questions.points AS max_points,
                AVG(quiz_submission_questions.points) AS avg_points,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points = quiz_questions.points
                    THEN 1
                    ELSE NULL
                  END
                ) AS correct_submissions,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points = 0
                     AND quiz_submission_questions.points < quiz_questions.points
                    THEN 1
                    ELSE NULL
                  END
                ) AS incorrect_submissions,
                COUNT(
                  CASE
                    WHEN quiz_submission_questions.points > 0
                     AND quiz_submission_questions.points < quiz_questions.points
                    THEN 1
                    ELSE NULL
                  END
                ) AS partly_correct_submissions
           FROM quiz_questions
      LEFT JOIN quiz_submission_questions
             ON quiz_submission_questions.quiz_question_id = quiz_questions.id
      LEFT JOIN quiz_submissions
             ON quiz_submissions.id = quiz_submission_questions.quiz_submission_id
          WHERE quiz_questions.quiz_id = '#{@quiz.id}'
            AND quiz_submissions.quiz_submission_time IS NOT NULL
       GROUP BY quiz_questions.id, quiz_questions.points, quiz_questions.position
       ORDER BY quiz_questions.position ASC
    SQL

    stats = ActiveRecord::Base.connection.execute(query)
      .index_by {|row| row['id'] }

    @quiz.questions.map do |question|
      default_stats = {
        'id' => question.id,
        'max_points' => question.points,
        'avg_points' => 0.0,
        'correct_submissions' => 0,
        'incorrect_submissions' => 0,
        'partly_correct_submissions' => 0,
      }

      # return default values for questions without submissions
      stats[question.id] || default_stats
    end
  end

  def box_plot_distributions
    query = <<-SQL.squish
      WITH raw_data AS (
            SELECT s.id, (s.fudge_points + SUM(q.points)) / #{@quiz.max_points} AS value
              FROM quiz_submissions AS s
        INNER JOIN quiz_submission_questions AS q ON q.quiz_submission_id = s.id
             WHERE s.quiz_id = '#{@quiz.id}'
               AND (s.quiz_submission_time IS NOT NULL)
          GROUP BY s.id
      ),
      details AS (
        SELECT value,
               ROW_NUMBER() OVER (ORDER BY value) AS row_number,
               SUM(1) OVER () AS total
          FROM raw_data
      ),
      quartiles AS (
        SELECT value,
               AVG(CASE WHEN row_number >= (FLOOR(total/2.0)/2.0)
                         AND row_number <= (FLOOR(total/2.0)/2.0) + 1
                        THEN value/1.0 ELSE NULL END
                   ) OVER () AS q1,
               AVG(CASE WHEN row_number >= (total/2.0)
                         AND row_number <= (total/2.0) + 1
                        THEN value/1.0 ELSE NULL END
                   ) OVER () AS median,
               AVG(CASE WHEN row_number >= (CEIL(total/2.0) + (FLOOR(total/2.0)/2.0))
                         AND row_number <= (CEIL(total/2.0) + (FLOOR(total/2.0)/2.0) + 1)
                        THEN value/1.0 ELSE NULL END
                   ) OVER () AS q3
          FROM details
      )
      SELECT MIN(CASE WHEN value >= q1 - ((q3-q1) * 1.5) THEN value ELSE NULL END) AS minimum,
             AVG(q1) AS q1,
             AVG(median) AS median,
             AVG(q3) AS q3,
             MAX(CASE WHEN value <= q3 + ((q3-q1) * 1.5) THEN value ELSE NULL END) AS maximum
        FROM quartiles
    SQL

    result = ActiveRecord::Base.connection.execute(query)

    {
      min: result.values.dig(0, 0),
      q1: result.values.dig(0, 1),
      median: result.values.dig(0, 2),
      q3: result.values.dig(0, 3),
      max: result.values.dig(0, 4),
    }
  end

  private

  def submissions
    # Remove the order applied by the default scope
    # but not all scopes to keep the quiz relation.
    @submissions ||= @quiz.submissions.reorder(nil).where_submitted(true)
  end
end
