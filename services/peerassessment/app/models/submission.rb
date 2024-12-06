# frozen_string_literal: true

class Submission < ApplicationRecord
  belongs_to :shared_submission
  has_one :peer_assessment, through: :shared_submission
  has_many :team_submissions, through: :shared_submission, source: :submissions
  has_many :reviews, -> { order(created_at: :asc) }
  has_many :conflicts, as: :conflict_subject
  has_one :grade
  has_many :pool_entries

  default_scope { order(created_at: :asc) }

  after_create :create_grade_object

  validates :user_id, presence: true
  validates :user_id, uniqueness: {scope: :shared_submission_id}
  validate :user_uniquenesses_per_peer_assessment, if: :shared_submission_id

  ######### DELEGATION ##########
  # for each attribute creates delegation of
  # :attribute and :attribute= to shared_submission
  %w[
    peer_assessment_id
    text
    submitted
    disallowed_sample
    gallery_opt_out
    additional_attempts
  ].each do |attr|
    delegate attr.to_sym, to: :shared_submission
    delegate :"#{attr}=", to: :shared_submission
  end
  ###############################

  def participants
    Participant.where(user_id:, peer_assessment_id:)
  end

  def handle_training_pool_entry
    pool = peer_assessment.training_pool
    return if disallowed_sample || !pool

    PoolEntry.create(
      resource_pool_id: pool.id,
      submission_id: id,
      available_locks: pool.initial_locks
    )
  end

  def handle_grading_pool_entry
    pool = peer_assessment.grading_pool
    return unless pool

    priority = pool.initial_locks # Base priority
    PoolEntry.create!(
      resource_pool_id: pool.id,
      submission_id: id,
      available_locks: pool.initial_locks,
      priority:
    )
  end

  def create_grade_object
    if grade.nil?
      self.grade = Grade.create! submission_id: id, delta: 0.0, absolute: false
    end
  end

  def average_votes
    GalleryVote.by_submission(id).average(:rating)
  end

  def votes
    GalleryVote.by_submission(id).count
  end

  def nominations
    Review.where(submission_id: team_submissions.pluck(:id))
      .not_suspended
      .where(
        award: true,
        submitted: true,
        step_id: peer_assessment.grading_step.id
      ).count
  end

  # Writes the grade of this submission to the course service. Set the "create"
  # flag to `true` if the result should be created when it does not exist yet.
  def write_course_result(create: false, recompute: false)
    # Check if there is already a result resource. Update or create accordingly.
    course_api = Xikolo.api(:course).value!
    result = course_api.rel(:result).get(id:).value!

    course_api.rel(:result).patch(
      {points: grade.compute_grade(recompute:) || 0},
      {id: result['id']}
    ).value!
  rescue Restify::ClientError => e
    raise unless e.code == 404
    return unless create

    course_api.rel(:item_user_results).post(
      {
        id:,
        points: grade.compute_grade(recompute:) || 0.0,
      },
      {item_id: peer_assessment.item_id,
      user_id:}
    ).value!
  end

  private

  def user_uniquenesses_per_peer_assessment
    submissions = self.class.joins(:shared_submission)
      .where(user_id:, shared_submissions: {
        peer_assessment_id: shared_submission.peer_assessment_id,
      })
    return unless (new_record? && submissions.exists?) ||
                  (persisted? && submissions.count > 1)

    errors.add(:user_id, 'has already a submission for this assessment')
  end
end
