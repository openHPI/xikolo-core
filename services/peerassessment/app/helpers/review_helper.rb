# frozen_string_literal: true

#
# Module containing all algorithms to retrieve submissions for reviewing.
#
module ReviewHelper
  # Retrieval algorithm for teaching assistants
  def retrieve_submission_as_sample(assessment_id, user_id)
    assessment = PeerAssessment.find assessment_id
    train_step = assessment.steps.detect {|step| step.instance_of? Training }
    training_pool = ResourcePool.find_by peer_assessment: assessment, purpose: 'training'

    # Abort if resources not present or the train step already begun
    return [] unless assessment && training_pool &&
                     train_step && !train_step.open

    retries = 5
    while retries > 0
      begin
        sample = get_sample training_pool, train_step, user_id
        return [sample] if sample
      rescue => e # Transaction rollback triggered
        puts e.message
      ensure
        retries -= 1
      end
    end

    []
  end

  # TA related sample retrieval
  def get_sample(pool, train_step, user_id)
    PoolEntry.transaction do
      entry = PoolEntry.lock.where(
        'resource_pool_id = ? AND available_locks > 0',
        pool.id
      ).order(Arel.sql('random()')).take # PSQL

      if entry
        # make sure team submissions are not reviewed multiple times
        entry.team_entries.each do |e|
          e.available_locks -= 1
          e.save!
        end

        next Review.create!(
          train_review: true,
          submission_id: entry.submission_id,
          step: train_step,
          user_id:,
          submitted: false
        )
      end
    end
  end

  # Student training review retrieval algorithm
  def retrieve_student_training_sample(assessment_id, user_id)
    # Retrieve training step
    assessment = PeerAssessment.find assessment_id
    training_step = assessment.training_step
    grading_step = assessment.grading_step
    user_submission = Submission
      .joins(:shared_submission)
      .find_by user_id:, shared_submissions: {peer_assessment_id: assessment.id}

    # Check prerequisites and abort if necessary
    return [] unless assessment && training_step &&
                     user_submission && training_step.open

    # Check for resume (max. one per user)
    unfinished_review = Review.find_by(
      user_id:,
      step_id: training_step.id,
      submitted: false,
      train_review: false
    )
    return [unfinished_review] if unfinished_review

    # 1. No pool handling required for the student training process
    # 2. Get all training reviews for this assessment
    # 3. Do not allow the user to get his own submission
    # 4. Do not allow the user to get her team members submissions
    # 5. Never return the same sample twice

    # exclude submissions of that were already reviewed by the user
    # and submissions by team members
    finished_reviews = Review.where(
      train_review: false,
      submitted: true,
      user_id:,
      step_id: training_step.id
    )

    # Make sure there are enough shared submissions left in the peer grading phase.
    # Excluding the own submission and the ones reviewed in the training step,
    # keep at least as many submissions unreviewed as required in the grading step.
    return [] if SharedSubmission
      .where(peer_assessment_id: assessment_id)
      .count - 1 - finished_reviews.count <= grading_step.required_reviews

    reviewed_submissions = finished_reviews.map(&:submission_id)
    team_submissions = user_submission.team_submissions.pluck(:id)
    unpermitted_sids = reviewed_submissions + team_submissions

    review = Review.where(
      'step_id = ? ' \
      'AND train_review = TRUE ' \
      'AND submitted = TRUE ' \
      'AND submission_id NOT IN (?)',
      training_step.id,
      unpermitted_sids
    ).reorder(Arel.sql('random()')).take

    return [] if review.nil?

    student_review = Review.new(
      submission_id: review.submission_id,
      user_id:,
      step_id: training_step.id,
      train_review: false,
      submitted: false
    )
    student_review.save ? [student_review] : []
  end

  # Student peer grading algorithm, which is the most resource intensive
  # algorithm and is thus governed by a memory pool.
  def retrieve_grading_review(assessment_id, user_id)
    assessment      = PeerAssessment.find assessment_id
    grading_step    = assessment.grading_step
    user_submission = Submission.joins(:shared_submission).find_by(
      user_id:,
      shared_submissions: {peer_assessment_id: assessment.id}
    )

    return [] unless assessment && grading_step.deadline.future? && user_submission

    # Check for resume (max. one per user)
    unfinished_reviews = Review.where(
      user_id:,
      step_id: grading_step.id,
      submitted: false,
      train_review: false
    )
    unfinished_reviews = unfinished_reviews.not_suspended
    return [unfinished_reviews.first] unless unfinished_reviews.empty?

    # Check if the user can do any more (additional) reviews
    finished_reviews = Review
      .where('submitted=TRUE AND user_id=? AND step_id=?', user_id, grading_step.id)
      .reject(&:suspended?)
    return [] if finished_reviews.count >= grading_step.required_reviews * 2

    # 1. Do not allow the user to get his own submission
    # 2. Do not allow the user to get her team members submissions
    # 3. Never return a review with the same submission twice
    # 4. Do not give users submissions they already trained on!
    # 5. Explicitly include suspended reviews here!
    # Note: Self-assessment is not interesting here, because there is no pooling for self-assessments
    unpermitted_sids = user_submission.team_submissions.pluck(:id)

    if assessment.training_step
      reviewed_submissions = Review.where(
        'user_id=? AND (step_id=? OR step_id=?) AND train_review = FALSE',
        user_id,
        grading_step.id,
        assessment.training_step.id
      ).pluck(:submission_id)
    else
      reviewed_submissions = Review.where(
        'user_id=? AND step_id=?',
        user_id,
        grading_step.id
      ).pluck(:submission_id)
    end

    # make sure that clones (team members submissions)
    # of reviewed submissions are not included
    reviewed_submissions.each do |reviewed_submission|
      unpermitted_sids.concat Submission.find(reviewed_submission).team_submissions.pluck(:id)
    end

    grading_pool_id = assessment.grading_pool.id
    retries = 0

    while retries < 5
      submission_id = nil

      begin
        max_prio = PoolEntry.where(
          'resource_pool_id=? AND available_locks > 0 AND submission_id NOT IN (?)',
          grading_pool_id,
          unpermitted_sids
        ).maximum(:priority)
        break unless max_prio # If there is no max prio, it means that there is no entry to be found regularly

        entry = PoolEntry.where(
          'resource_pool_id=? AND available_locks > 0 AND submission_id NOT IN (?) AND priority >= ?',
          grading_pool_id,
          unpermitted_sids,
          max_prio - retries
        ).order('priority DESC').limit(100).sample

        raise unless entry

        entry.with_lock do
          PoolEntry.transaction do
            if entry.available_locks <= 0
              retries -= 1 # We want a new record, but without the retry 'bonus'
              raise
            end

            entry.available_locks -= 1
            entry.priority -= 1 unless entry.priority == 0
            entry.save!

            submission_id = entry.submission_id
          end
        end
      rescue StandardError
        retries += 1
      end

      next unless submission_id

      student_review = Review.new(
        submission_id:,
        user_id:,
        step_id: grading_step.id,
        train_review: false,
        submitted: false
      )
      return [student_review] if student_review.save
    end

    # Fallback mechanism: If the student does not have his required amount of reviews and there are none left to grade
    # AND the deadline for the previous step has passed (!),
    # THEN assign an "overload" Review (bypasses the pooling)
    # The same is true for additional reviews: Each student willing to grade additional reviews should be able to do so.
    additional_review = finished_reviews.size >= grading_step.required_reviews
    entry = PoolEntry.where(
      'resource_pool_id = ? AND available_locks = 0 AND submission_id NOT IN (?)',
      grading_pool_id,
      unpermitted_sids
    ).order('priority DESC').limit(100).sample

    if entry
      priority_changed = false

      unless (entry.priority == 0) || !additional_review
        entry.with_lock(true) do
          entry.priority -= 1
          priority_changed = true
          entry.save!
        end
      end

      student_review = Review.new(
        submission_id: entry.submission_id,
        user_id:,
        step_id: grading_step.id,
        train_review: false,
        submitted: false
      )
      student_review.ignore_pooling = (!additional_review && priority_changed)
      return [student_review] if student_review.save
    end
    []
  end

  # Self assessment phase retrieval
  def get_self_assessment(assessment_id, user_id)
    assessment = PeerAssessment.find assessment_id
    submission = Submission.joins(:shared_submission).find_by(
      user_id:,
      shared_submissions: {peer_assessment_id: assessment_id}
    )
    review = Review.find_by(
      user_id:,
      step_id: assessment.self_assessment_step.id,
      submission_id: submission.id
    )

    unless review
      # Create a new self assessment review
      submission = Submission.joins(:shared_submission).find_by(
        user_id:,
        shared_submissions: {peer_assessment_id: assessment_id}
      )
      review = Review.new(
        submitted: false,
        step_id: assessment.self_assessment_step.id,
        user_id:,
        submission_id: submission.id,
        train_review: false,
        deadline: 6.hours.from_now
      )
      review.clear_worker # No worker needed
      review.save
    end

    [review.reload]
  end

  def get_team_evaluation_reviews(assessment_id, user_id)
    assessment = PeerAssessment.find assessment_id
    submission = Submission.joins(:shared_submission).find_by(
      user_id:,
      shared_submissions: {peer_assessment_id: assessment_id}
    )
    team_submission_ids = submission.team_submissions.pluck(:id)
    team_submission_ids.delete submission.id
    reviews = Review.where(
      user_id:,
      step_id: assessment.self_assessment_step.id
    ).where(submission_id: team_submission_ids)

    if reviews.empty?
      reviews = []
      team_submission_ids.each do |submission_id|
        review = Review.new(
          step_id: assessment.self_assessment_step.id,
          user_id:,
          submission_id:,
          train_review: false
        )
        review.clear_worker
        review.save
        reviews << review
      end
    end

    reviews
  end

  def get_ta_review(user_id, submission_id)
    submission = Submission.find submission_id

    # Check whether a review exists
    review = Review.find_by(
      submission_id:,
      step_id: submission.peer_assessment.grading_step.id
    )
    return [review] if review

    text = <<~TEXT.strip
      **Please note: This review has been created by a teaching assistant \
      as you have not received any reviews form your peers.**
    TEXT

    review = Review.create!(
      submission_id:,
      text:,
      submitted: false,
      step_id: submission.peer_assessment.grading_step.id,
      train_review: false,
      user_id:
    )

    # Ensure that there is a user addition for the TA
    unless Participant.exists?(peer_assessment_id: submission.peer_assessment.id, user_id:)
      ua = Participant.new(peer_assessment_id: submission.peer_assessment.id, user_id:)
      ua.expertise = 4 unless submission.peer_assessment.training_step.nil?
      ua.grading_weight = 1.0
      ua.save validate: false
    end

    [review]
  end
end
# rubocop:enable all
