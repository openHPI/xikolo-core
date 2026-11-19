# frozen_string_literal: true

module QuizService
class QuizSubmission < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :quiz_submissions
  has_many :quiz_submission_questions, dependent: :destroy
  has_one :quiz_submission_snapshot, dependent: :destroy
  belongs_to :quiz
  belongs_to :user, class_name: 'AccountService::User'
  has_one :item, through: :quiz, class_name: 'CourseService::Item'

  default_scope -> { order(:created_at) }

  class << self
    # FIXME: After call of this scope, model will be loaded!
    def sort_by_rating
      all.sort {|x, y| y.points <=> x.points }
    end

    def where_submitted(submitted)
      if submitted
        where.not(quiz_submission_time: nil)
      else
        where(quiz_submission_time: nil)
      end
    end

    def by_user(uid)
      where(user_id: uid)
    end

    def unsubmitted
      where(quiz_submission_time: nil)
    end
  end

  def snapshot!(submission_data)
    QuizSubmissionSnapshot
      .find_or_create_by(quiz_submission: self)
      .tap do |snapshot|
        snapshot.data = submission_data
        snapshot.save
      end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def schedule_report!
    ReportQuizResultsJob.perform_later id
  end

  def report_result!
    ResultReporter.new(quiz_id).report!(self)
  end

  def points
    (quiz_submission_questions.sum(&:points) + fudge_points).round(1)
  end

  def question_count
    quiz_submission_questions.length
  end

  def max_points
    return quiz.max_points unless quiz.question_pool?

    Question.where(id: quiz_submission_questions.select(:quiz_question_id)).sum(:points)
  end

  def snapshot_id
    quiz_submission_snapshot&.id
  end

  def quiz_access_time
    created_at
  end

  def submitted
    !quiz_submission_time.nil?
  end

  # Did the learner reach the exam's passing threshold? Exams grade against the
  # maximum points of the question set the learner actually got.
  def passed?
    return false if quiz.pass_percentage.blank? || max_points.to_f.zero?

    points.to_f * 100 / max_points >= quiz.pass_percentage
  end

  # Was this object inserted or updated on last save?
  def just_created?
    saved_change_to_attribute?(:created_at, from: nil)
  end

  def preaggregate_statistics!
    return unless submitted

    questions = if quiz.question_pool?
                  Question.where(id: quiz_submission_questions.select(:quiz_question_id))
                else
                  quiz.questions
                end
    questions.each do |quiz_question|
      # Arguments for `perform` must be simple JSON data types.
      # The date string is parsed as `DateTime` in the job.
      UpdateQuestionStatisticsJob.set(wait: 2.hours).perform_later(quiz_question.id, Time.zone.now.to_s)
    end
  end
end
end
