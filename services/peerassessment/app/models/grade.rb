# frozen_string_literal: true

class Grade < ApplicationRecord
  belongs_to :submission, dependent: :destroy

  default_scope { order(created_at: :asc) }
  scope :for_user_in_assessment,
    lambda {|user_id, peer_assessment_id|
      joins(submission: :shared_submission)
        .where(submissions: {user_id:}, shared_submissions: {peer_assessment_id:})
    }

  ### Grade computation functions ###

  # Final grade computation main entry point
  def compute_grade(recompute: false)
    # Either the grading or the self-assessment must be finished for the grade to compute
    if submission.shared_submission.peer_assessment.steps[-2].deadline.past?
      participant = Participant.find_by peer_assessment_id: submission.peer_assessment.id, user_id: submission.user_id

      unless participant.can_receive_grade?
        bonus_points_will_change!
        self.bonus_points = [] # No bonus points
        self.base_points = 0.0 # No points at all
        save!

        return 0.0 # Zero grade
      end

      # Absolute delta always overwrites everything else
      return delta if absolute

      # If the grade has already been computed, there is no need to recompute the base points.
      # External changes such as the application of a new delta will trigger this computation with a recompute flag set.
      unless base_points && !recompute
        received_reviews = collect_received_reviews
        self.base_points = 0.0

        unless received_reviews.empty?
          self.base_points = median_grade(received_reviews).round(1)
        end

        save!
      end

      gather_bonus_points
      overall_grade = base_points
      overall_grade += delta if delta

      bonus_points&.each do |bonus|
        overall_grade += bonus.last.to_f
      end

      # 1. A grade can not be negative
      # 2. If the peer assessment is a main exercise, the points are capped at
      #    the max points to prevent issues with certificates.
      final_grade = [overall_grade, 0.0].max
      final_grade = final_grade.round(1)
      update_course_result(final_grade) if recompute

      final_grade
    end
  end

  ### Experimental weighted average (base point) computation ###
  def weighted_average(received_reviews)
    result = 0.0
    weight_sum = 0.0

    received_reviews.each do |review|
      weight = Participant.find_by(
        peer_assessment_id: submission.peer_assessment_id,
        user_id: review.user_id
      ).grading_weight
      weight_sum += weight

      result += (review.compute_grade * weight)
    end

    # Average the base points
    result / weight_sum
  end

  ### Simple (non-weighted) average of grades ###

  def average_grade(received_reviews)
    result = 0.0

    received_reviews.each do |review|
      result += review.compute_grade
    end

    result / received_reviews.size.to_f
  end

  ### Per-rubric median computation ###

  def median_grade(received_reviews)
    result = 0.0

    # If there is only one or two reviews, take the simple average
    if received_reviews.size <= 2
      return average_grade received_reviews
    end

    submission.peer_assessment.rubrics.each do |rubric|
      option_ids = rubric.rubric_options.map(&:id)

      chosen_options = received_reviews.map do |r|
        (r.optionIDs & option_ids).first # Return the selected rubric option by this review and rubric
      end

      # If the reviewer did not select any option return 0 points.
      points = chosen_options.map do |oid|
        oid.nil? ? 0 : RubricOption.find(oid).points
      end
      points.sort!

      # Now we have all options the reviewers chose for this rubric and submission
      # Translate these options into points, order by points, and finally apply the median.
      # 1. If there is an even amount of reviews (> 2), then average the median (middle) _pair_.
      # 2. If there is an off amount of reviews (> 2), take the median.

      median_pos = (points.size / 2).floor

      if received_reviews.size.odd?
        result += points[median_pos]
      else
        result += (points[median_pos] + points[median_pos - 1]) / 2.0
      end
    end

    result
  end

  ### Regrading eligibility

  def regradable?
    reviews = collect_received_reviews
    reviews_count = reviews.size
    min_reviews_with_consensus = calc_required_reviews_with_consensus(reviews_count)
    received_less_than_min_reviews(reviews_count) || no_consensus_in_reviews?(reviews, min_reviews_with_consensus)
  end

  ### Bonus calculation functions ###

  def gather_bonus_points
    self_assessment_bonus
    usefulness_bonus
    team_evaluation_bonus
    save!
  end

  def self_assessment_bonus
    self_assessment = submission.peer_assessment.self_assessment_step

    unless self_assessment.nil? || base_points.nil?
      review = Review.find_by(
        user_id: submission.user_id,
        submitted: true,
        submission_id: submission.id,
        step_id: self_assessment.id
      )

      # The step could be optional, hence, no review possible
      return unless review

      max_points = submission.peer_assessment.max_points

      # Look at the base points (which represent the average of received
      # points) and compare them to the self assessment
      #
      # 10% deviation threshold (_max_ points)
      if (review.compute_grade - base_points).abs <= (max_points * 0.1)
        # Minimum of 0.5 bonus points, else 5% of _max_ points
        bonus = [0.5, 0.05 * max_points].max
        bonus_points_will_change!

        if bonus_points.nil?
          self.bonus_points = []
        else
          self.bonus_points = bonus_points.reject {|e| e.first == 'self_assessment' }
        end

        self.bonus_points = bonus_points + [['self_assessment', bonus.to_s]]
        save!
      end
    end
  end

  def usefulness_bonus
    written_reviews = Review.where(
      user_id: submission.user_id,
      step_id: submission.peer_assessment.grading_step.id
    )
    bonus = 0.0

    written_reviews.each do |review|
      if review.feedback_grade
        bonus += (review.feedback_grade.to_f / 3).round(1)
      end
    end

    return unless bonus > 0.0

    bonus_points_will_change!

    if bonus_points.nil?
      self.bonus_points = []
    else
      self.bonus_points = bonus_points.reject {|e| e.first == 'usefulness' }
    end

    self.bonus_points = bonus_points + [['usefulness', bonus.round(1).to_s]]
    save!
  end

  def team_evaluation_bonus
    return if submission.peer_assessment.self_assessment_step.nil?

    team_ids = submission.team_submissions.pluck(:user_id)
    team_ids.delete submission.user_id
    team_reviews = Review.where(
      submission_id: submission.id,
      step_id: submission.peer_assessment.self_assessment_step.id,
      submitted: true
    ).where(user_id: team_ids)

    return if team_reviews.empty?

    rubrics = Rubric.unscoped.where(
      peer_assessment_id: submission.peer_assessment.id,
      team_evaluation: true
    )
    max_points = submission.peer_assessment.max_points

    rating = team_reviews.filter_map(&:compute_grade).sum.to_f
    rating /= rubrics.count # divide by number of rubrics per review
    rating /= 3 # each rating can have at most 3 points
    rating /= team_reviews.count # average over all team members that submitted a review
    rating *= [1, 0.1 * max_points].max

    return unless rating > 0.0

    if bonus_points.nil?
      self.bonus_points = []
    else
      self.bonus_points = bonus_points.reject {|e| e.first == 'team_evaluation' }
    end

    bonus_points << ['team_evaluation', rating.round(1).to_s]
    save!
  end

  def collect_received_reviews
    # Include reviews on team submissions
    submission_ids = submission.team_submissions.pluck(:id)
    received_reviews = Review
      .where(submission_id: submission_ids)
      .where(submitted: true)
      .where(step_id: submission.peer_assessment.grading_step.id)
    # Ignore suspended or reported reviews for the calculation of base points
    received_reviews.accounted
  end

  # Will be called as soon a recompute is triggered
  def update_course_result(points)
    course_api = Xikolo.api(:course).value
    return unless course_api

    result = course_api.rel(:result).get(id: submission_id).value
    return unless result
    return if result['points'] == points

    course_api.rel(:result).patch(
      {points:},
      {id: submission_id}
    ).value
  end

  def no_consensus_in_reviews?(received_reviews, min_reviews_with_consensus)
    # no consensus has been achieved in one of the rubrics ==> enable regrading
    # consensus has been achieved for all rubrics ==> do not enable regrading
    submission.peer_assessment.rubrics.any? do |rubric|
      chosen_options = get_chosen_options_for_rubric(received_reviews, rubric)
      biggest_consensus_in_rubric = calc_existing_reviews_with_consensus(
        chosen_options,
        min_reviews_with_consensus
      )
      biggest_consensus_in_rubric < min_reviews_with_consensus
    end
  end

  # more than half of the reviews have to have consensus (4 reviews => 3 need
  # consensus (therefore: +.5))
  def calc_required_reviews_with_consensus(reviews_count)
    ((reviews_count.to_f + 0.5) / 2).ceil
  end

  def get_chosen_options_for_rubric(received_reviews, rubric)
    option_ids = rubric.rubric_options.pluck(:id)
    received_reviews.filter_map {|r| (r.optionIDs & option_ids).first }
  end

  def calc_existing_reviews_with_consensus(chosen_options, min_reviews_with_consensus)
    consensus_map = Hash.new(0)
    chosen_options.each do |oid|
      # some peer assessments contain rubrics with different options that
      # provide the same amount of points
      points = RubricOption.find(oid).points
      consensus_map[points] = consensus_map[points] + 1
      break if consensus_map[points] >= min_reviews_with_consensus
    end

    # sort the consensus_map for a rubric by value, biggest value first
    consensus_map.values.max
  end

  # participants that have received less than 3 reviews are always allowed to
  # ask for a regrading
  def received_less_than_min_reviews(reviews_count)
    reviews_count <= 2
  end
end
# rubocop:enable all
