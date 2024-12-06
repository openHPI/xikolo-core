# frozen_string_literal: true

class Training < Step
  before_update :update_validation_check
  after_create  :create_pool

  REQUIRED_TA_REVIEWS = 5.0

  def on_step_enter(user_id)
    # Create submission entry for the training pool if user enters this step
    s = Submission.joins(:shared_submission).find_by(
      user_id:,
      shared_submissions: {peer_assessment_id:}
    )
    s.handle_training_pool_entry if s&.submitted
  end

  def completion(curr_user)
    # If the step is optional there are no reviews required
    finished_reviews = Review.where(user_id: curr_user, submitted: true, step_id: id).count.to_f

    # An optional step is skippable if no review has been submitted yet
    # Otherwise, it is complete
    if optional
      finished_reviews == 0.0 ? 0.0 : 1.0
    else
      # Ratio of required and finished train reviews
      [finished_reviews / required_reviews, 1.0].min
    end
  end

  def can_be_opened?
    reviews = Review.where step: self, train_review: true, submitted: true
    reviews.count >= REQUIRED_TA_REVIEWS
  end

  def self.required_ta_reviews
    REQUIRED_TA_REVIEWS
  end

  def update_validation_check
    if open_changed?
      # Check if the training can be opened
      unless can_be_opened?
        errors.add :base, 'Preconditions for opening the training unfulfilled'
        throw :abort
      end

      # Destroy lingering training reviews
      Review.where(train_review: true, submitted: false, step_id: id).delete_all
    end

    true
  end

  def create_pool
    ResourcePool.create! peer_assessment:, purpose: 'training'
  end

  # override
  def advance_team_to_step?
    true
  end
end
