# frozen_string_literal: true

class QuizSubmission < ApplicationRecord
  has_many :quiz_submission_questions, dependent: :destroy
  has_one :quiz_submission_snapshot, dependent: :destroy
  belongs_to :quiz

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
    ReportQuizResultsWorker.perform_async id
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

  def quiz_access_time
    created_at
  end

  def submitted
    !quiz_submission_time.nil?
  end

  def within_time_limit?(timestamp)
    quiz.unlimited_time || (timestamp.to_i <= created_at.in_time_zone.to_i + quiz.time_limit_seconds)
  end

  # Was this object inserted or updated on last save?
  def just_created?
    saved_change_to_attribute?(:created_at, from: nil)
  end

  def preaggregate_statistics!
    return unless submitted

    quiz.questions.each do |quiz_question|
      # Arguments for `perform` must be simple JSON data types.
      # The date string is parsed as `DateTime` in the worker.
      UpdateQuestionStatisticsWorker.perform_in(2.hours, quiz_question.id, Time.zone.now.to_s)
    end
  end
end
