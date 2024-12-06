# frozen_string_literal: true

class Participant < ApplicationRecord
  belongs_to :peer_assessment
  belongs_to :group, optional: true
  has_many :group_members,
    ->(participant) { where.not(user_id: participant.user_id) },
    through: :group,
    source: :participants

  validates :user_id, presence: true, uniqueness: {scope: :peer_assessment}

  def handle_update(params)
    type = params[:update_type]
    case type
      when 'advance_to'
        advance_to params
      when 'advance'
        step = Step.find_by id: current_step
        if step&.skippable?(user_id)
          skip params
        else
          advance params
        end
      else
        errors.add :base, 'invalid_type'
    end
    save if errors.full_messages.empty?
  end

  def state_for(step)
    if finished? step
      :finished
    elsif open? step
      :open
    else
      :locked
    end
  end

  def currently_on?(step)
    current_step == step.id
  end

  def advance(_)
    # Check if the current step has been completed
    step = Step.find_by id: current_step

    if step.nil?
      next_step = peer_assessment.steps.first
    else
      if step.complete? user_id
        completed_will_change!
        completed << current_step
      else
        errors.add :base, 'step_incomplete'
        return
      end

      next_step = step.next_step
    end

    if next_step.nil?
      errors.add :base, 'no_next_step'
    else
      if next_step.advance_team?
        group_members.each do |group_member|
          group_member.advance_to step_id: next_step.id
          group_member.save if group_member.errors.full_messages.empty?
        end
      end

      self.current_step = next_step.id
      next_step.on_step_enter user_id
    end
  end

  def advance_to(params)
    # Advance user to the specified step
    step = Step.find_by(id: params[:step_id])

    if step.nil?
      errors.add :base, 'invalid_step'
    else
      self.current_step = step.id
      step.on_step_enter user_id

      # Trigger on step enter for all previous steps
      steps = Step.where(peer_assessment_id: step.id).where(position: ...step.position)
      steps.each {|s| s.on_step_enter(user_id) }
    end
  end

  def skip(_)
    step = Step.find current_step

    if step.optional
      skipped_will_change!
      skipped << current_step

      next_step = step.next_step

      if next_step.nil?
        errors.add :base, 'no_next_step'
      else
        self.current_step = next_step.id
        next_step.on_step_enter user_id
      end
    else
      errors.add :base, 'not_optional'
    end
  end

  # Checks if the user is qualified to receive a grade
  def can_receive_grade?
    # The main indicator is that the user advanced to the last step, as well as the completion of everything required
    completed_mandatory_second_last_step? \
      || arrived_in_optional_second_last_step? \
      || arrived_in_last_step?
  end

  ### Currently unused functionality ###
  # Required for the experimental weighted average approach, which was replaced with a median calculation.

  def compute_weight
    # Computes the grading weight of the user represented by this user addition
    # This will be triggered on PeerGrading#on_step_enter and includes the following factors:
    ## 1. Amount of legitimate reports (conflicts) filed against this user (spanning all peer assessments)
    ## 2. Ratio of filed reports and legitimately filed reports
    ## 3. Average of the users' review usefulness (spanning all peer assessments)
    ## 4. Training competence index, if there was a training and if the user participated

    factors = %i[conflict usefulness]

    unless peer_assessment.training_step.nil?
      factors << :training
    end

    weight = 0.5 # Minimum weight

    factors.each do |factor|
      # Each factor may contribute at max 50% / number_of_factors (i.e. 25% for
      # two factors), which adds up to a max of 100% weight
      weight += send(:"#{factor}_weight") * (0.5 / factors.size)
    end

    self.grading_weight = weight.round 3
    save
  end

  def training_weight
    # Get the training phase reviews and their respective TA reviews
    training_reviews = Review.where(
      step_id: peer_assessment.training_step.id,
      train_review: false,
      submitted: true,
      user_id:
    ).order('submission_id ASC')

    teacher_reviews = Review.where(
      train_review: true,
      submitted: true
    ).where(submission_id: training_reviews.map(&:submission_id)).order('submission_id ASC')

    sum = 0.0
    reviews = training_reviews.zip teacher_reviews

    # For each rubric: Compute deviation per rubric using cubic smoothing until 20%
    peer_assessment.rubrics.each do |rubric|
      options = rubric.rubric_options.map(&:id)

      reviews.each do |training_review, ta_review|
        ta_option = (ta_review.optionIDs & options).first
        student_option = (training_review.optionIDs & options).first

        if ta_option == student_option
          # Match
          sum += 1.0

        elsif (
                (options.first == ta_option) &&
                (options.last == student_option)
              ) || (
                (options.last == ta_option) &&
                (options.first == student_option)
              )

          # Catch the case where the student and the TA have a 100% deviation
          # (this is not caught via the difference of index positions)
          sum += 0.0

        else
          # Compute the deviation in the distance of list position from the
          # reference value
          reference = options.index ta_option
          chosen    = options.index student_option
          distance  = (reference - chosen).abs.to_f
          deviation = distance / options.count

          # Partial function implementation
          if (deviation <= 0.2) || (distance == 1)
            # Up to 20% deviation (or a distance of only one) will cause a
            # reduced weight penalty, since it is pretty close to the TA grade
            sum += 1.0 - (0.0025 * (deviation**3))
          else
            # After 20%, linear scaling kicks in until 0% are reached (meaning
            # that the deviation is taken as it is)
            sum += 1.0 - deviation
          end
        end
      end
    end

    # The final weight will be the average over the number of rubrics * reviews
    sum / (peer_assessment.rubrics.count * training_reviews.count)
  end

  def usefulness_weight
    # Average feedback grade this user received for his written reviews
    avg = Review.joins(:step).where(
      user_id:,
      steps: {type: 'PeerGrading'}
    ).where.not(feedback_grade: nil).average(:feedback_grade)

    # Benefit of the doubt: Give the user a 2-star weight (which is the
    # good-middle rating, 66.6%)
    return 0.75 unless avg

    # Based on the average given by the DB, compute the weight (with 3 being
    # 100% on the rating scale and 0 being 0% -> 33.3% steps)
    avg.to_f / 4
  end

  private

  def finished?(step)
    if currently_on?(step)
      step.complete? user_id
    else
      completed?(step) || skipped?(step)
    end
  end

  def completed?(step)
    completed.include? step.id
  end

  def skipped?(step)
    skipped.include? step.id
  end

  def open?(step)
    return false unless step.open?

    if currently_on?(step)
      true
    elsif !current_step # The user has not started the assessment yet
      step.first?
    else
      next_step?(step) && can_advance_past_current_step?
    end
  end

  def next_step?(step)
    step.previous_step && step.previous_step.id == current_step
  end

  def can_advance_past_current_step?
    current_step_object = Step.find current_step
    current_step_object.optional || current_step_object.complete?(user_id)
  end

  def arrived_in_last_step?
    current_step == peer_assessment.steps.last.id
  end

  def arrived_in_optional_second_last_step?
    second_last_step.optional && (current_step == second_last_step.id)
  end

  def completed_mandatory_second_last_step?
    second_last_step.completion(user_id).to_d == BigDecimal('1.0')
  end

  def second_last_step
    peer_assessment.steps[-2]
  end
end
# rubocop:enable all
