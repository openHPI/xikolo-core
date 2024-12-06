# frozen_string_literal: true

class Quiz < ApplicationRecord
  has_paper_trail
  has_many :questions, dependent: :destroy
  has_many :submissions, class_name: 'QuizSubmission', dependent: :destroy
  has_many :additional_attempts, class_name: 'AdditionalQuizAttempt', dependent: :delete_all

  after_commit(on: :destroy) do
    Xikolo::S3.extract_file_refs(instructions).each do |uri|
      Xikolo::S3.object(uri).delete
    end
  end

  validates :time_limit_seconds,
    :allowed_attempts,
    numericality: {only_integer: true, greater_than: 0}

  def attempt!(user_id, additional_params = {})
    with_lock do
      existing = submission_pool_for(user_id).take
      next existing if existing

      submissions.build(
        additional_params.merge(user_id:)
      ).tap do |submission|
        if attempts_left?(user_id)
          submission.save
        else
          submission.errors.add(:base, 'no_attempts_left')
        end
      end
    end
  end

  def current_quiz
    @current_quiz ||= Quiz.find(id)
  end

  def current_time_limit_seconds
    current_quiz.time_limit_seconds
  end

  def current_unlimited_time
    current_quiz.unlimited_time
  end

  def current_allowed_attempts
    current_quiz.allowed_attempts
  end

  def current_unlimited_attempts
    current_quiz.unlimited_attempts
  end

  def max_points
    questions.sum(:points)
  end

  def avg_points
    subs = submissions.where_submitted(true)
    points = subs.joins(:quiz_submission_questions).sum(:points)
    avg_points = (points + subs.sum(:fudge_points)) / subs.size.to_f
    avg_points.nan? ? 0.0 : avg_points
  end

  def stats
    @stats ||= SubmissionStatistics.new(self)
  end

  private

  def attempts_left?(user_id)
    return true if unlimited_attempts

    attempts = submissions.where(user_id:).where_submitted(true).count
    additional = additional_attempts.find_by(user_id:)&.count.to_i

    allowed_attempts + additional - attempts > 0
  end

  def submission_pool_for(user_id)
    submissions.unsubmitted.by_user(user_id)
  end
end
