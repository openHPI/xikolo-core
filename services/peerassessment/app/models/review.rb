# frozen_string_literal: true

class Review < ApplicationRecord
  require 'sidekiq/api'

  belongs_to :step
  belongs_to :submission
  has_one  :shared_submission, through: :submission
  has_one  :peer_assessment, through: :shared_submission
  has_many :conflicts, as: :conflict_subject

  validates :deadline, :user_id, presence: true

  # Flag for the worker scheduling to ignore the pooling in the cleanup worker
  attr_accessor :ignore_pooling

  default_scope { order(created_at: :asc) }

  scope :join_conflicts_on_submission, lambda {
    joins <<~SQL.squish
      LEFT JOIN conflicts
        AS submission_conflicts
        ON submission_conflicts.conflict_subject_id = reviews.submission_id
        AND submission_conflicts.reporter = reviews.user_id
    SQL
  }
  scope :no_conflict_on_submission, lambda {
    where <<~SQL.squish
      submission_conflicts.id IS NULL OR submission_conflicts.reporter != reviews.user_id
    SQL
  }
  scope :join_conflicts_on_review, lambda {
    joins <<~SQL.squish
      LEFT JOIN conflicts AS review_conflicts ON review_conflicts.conflict_subject_id = reviews.id
    SQL
  }
  scope :no_conflict_on_review, -> { where(review_conflicts: {id: nil}) }
  scope :not_suspended, -> { join_conflicts_on_submission.no_conflict_on_submission }
  scope :not_accused, -> { join_conflicts_on_review.no_conflict_on_review }
  scope :accounted, lambda {
    join_conflicts_on_submission.join_conflicts_on_review.no_conflict_on_submission.no_conflict_on_review
  }

  validate :check_open_training_update, on: :update
  validate :check_submission_exists

  before_save :check_submitted_state
  after_save :check_feedback_state
  before_destroy :check_training_review_destruction
  after_destroy :clear_worker
  after_create :schedule_worker

  before_validation :set_deadline, on: :create

  def extend_deadline
    if extended
      errors.add :deadline, 'You can no longer extend the deadline.'
    else
      new_deadline = [deadline + Review.extension_deadline, step.deadline].min
      self.deadline = new_deadline
      self.extended = true
    end

    save
  end

  # Schedules a sidekiq worker to collect (destroy) the review if the deadline is reached
  # Skipping callbacks to prevent unwanted
  # check_feedback_state callback and workers to get triggered.
  # rubocop:disable Rails/SkipsModelValidations
  def schedule_worker(explicit_deadline: nil, clear: true)
    clear_worker if worker_jid && clear
    scheduled_time = explicit_deadline || (deadline + 5.minutes)
    # Make sure the worker is scheduled for the future, otherwise it removes the review immediately
    if scheduled_time.future? && !teacher_review?
      update_column :worker_jid, ReviewCleanupWorker.perform_at(scheduled_time, id, ignore_pooling)
    end
  end
  # rubocop:enable all

  # Deletes the sidekiq worker associated with this review. Possibly extremely slow with many jobs...
  def clear_worker
    Sidekiq::ScheduledSet.new.find_job(worker_jid).try :delete
  end

  def set_deadline
    self.deadline = [DateTime.now + Review.relative_deadline, step.deadline].min
    true
  end

  # Relative deadline for the expiration of the review
  def self.relative_deadline
    6.hours
  end

  def self.extension_deadline
    2.hours
  end

  # Selected rubric options by the reviewer
  def rubric_options
    options = []
    optionIDs.each do |id|
      obj = RubricOption.find id
      options << obj if obj
    end
  end

  # Grade given by this review
  def compute_grade
    return nil unless submitted

    grade = 0

    optionIDs.each do |oid|
      option = RubricOption.find(oid)
      next unless option

      grade += option.points
    end

    grade
  end

  def suspended?
    # Important: Do not filter for open or closed reports here, since the reviews stays suspended regardless!
    Conflict.exists?(conflict_subject_id: submission_id, reporter: user_id)
  end

  def accused?
    # If a review is accused (open or closed), it does not count towards the grade of the reporter.
    Conflict.exists?(conflict_subject_id: id, open: true) || Conflict.exists?(conflict_subject_id: id, open: false)
  end

  private

  ### Validation Methods and Callbacks ###

  def check_open_training_update
    if step.instance_of?(Training) && step.open && train_review
      # Abort, no updates for training samples possible after the training phase opened
      errors.add :base, 'Training samples can not be edited after the training has been opened'
    end
  end

  def check_submitted_state
    if !submitted_was && submitted && step.is_a?(PeerGrading)
      submission_id = Submission.joins(:shared_submission)
        .find_by(user_id:, shared_submissions: {peer_assessment_id: shared_submission.peer_assessment_id})
        .try :id
      return unless submission_id

      # Boost the reviewers grading priority
      change_grading_priority(0.5)
    end

    true
  end

  def check_submission_exists
    unless Submission.exists? submission_id
      errors.add :submission_id, 'The referenced submission does not exist!'
    end
  end

  def check_training_review_destruction
    # ONLY delete a review if it is a train review! (normal students do not have the possibility to delete reviews).
    # The pool entry lock stays the same since the TA does not want the review to go back into the pool.
    # (Reviews deleted by Sidekiq workers supress validations)

    unless train_review
      errors.add :base, 'You can not delete regular reviews. Only sample reviews for the training phase can be deleted.'
      throw :abort
    end

    true
  end

  def check_feedback_state
    # User rated the review. Update the result on the course service accordingly.
    return unless feedback_grade_before_last_save.nil?
    return if feedback_grade.nil?

    ReviewRatingWorker.perform_async(
      user_id,
      shared_submission.peer_assessment_id
    )
  end

  def teacher_review?
    account_api = Xikolo.api(:account).value!
    user = account_api.rel(:user).get(id: user_id).value!
    permissions = user.rel(:permissions).get.value!
    permissions.include?('peerassessment.submission.manage')
  end

  def change_grading_priority(delta)
    grading_pool_id = peer_assessment.grading_pool.id
    submission = Submission.joins(:shared_submission)
      .find_by(user_id:, shared_submissions: {peer_assessment_id: shared_submission.peer_assessment_id})
    entry = PoolEntry.find_by(submission_id: submission.id, resource_pool_id: grading_pool_id)

    entry.with_lock do
      entry.priority += delta
      entry.save!
    end
  end
end
