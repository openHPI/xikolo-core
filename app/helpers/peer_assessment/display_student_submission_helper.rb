# frozen_string_literal: true

# TODO: Do not use instance variables for passing state into views
# rubocop:disable Rails/HelperInstanceVariable

module PeerAssessment::DisplayStudentSubmissionHelper
  def teachermode_step_path(step_name, peer_assessment_id, user_id)
    step_path = nil
    step_id = 'nonsense'

    case step_name
      when :results
        api_step = api.rel(:results)
        step_path = 'results'
        is_reviewed = false
      when :submission
        api_step = api.rel(:assignment_submissions)
        step_path = 'submission'
        is_reviewed = false
      when :self_assessment
        api_step = api.rel(:self_assessments)
        step_path = 'self_assessments'
        is_reviewed = true
      when :training
        api_step = api.rel(:trainings)
        step_path = 'training/evaluate'
        is_reviewed = true
      when :peer_grading
        api_step = api.rel(:peer_gradings)
        step_path = 'reviews'
        is_reviewed = true
    end

    steps = api_step.get(peer_assessment_id:).value!
    step_id = steps.first.id unless steps.first.nil?

    if is_reviewed
      api_reviews = api.rel(:reviews)
      submitted_reviews = api_reviews.get(
        user_id:,
        step_id:,
        peer_assessment_id:,
        submitted: true
      ).value!

      reviews = api_reviews.get(
        user_id:,
        step_id:,
        peer_assessment_id:
      ).value!

      # in case there is only one review, that isn't submitted, @...draft is used for showing a hint
      case step_name
        when :training
          @train_draft = true if unsubmitted_reviews?(reviews, submitted_reviews)
        when :peer_grading
          @peer_assess_draft = true if unsubmitted_reviews?(reviews, submitted_reviews)
        when :self_assessment
          @self_assess_draft = true if unsubmitted_reviews?(reviews, submitted_reviews)
      end

      review_count = submitted_reviews.count
    end

    if step_is_unreviewed_or_has_reviews?(review_count)
      # TODO: Path helper possible?
      "/peer_assessments/#{peer_assessment_id}/steps/#{step_id.to_param}" \
        "/#{step_path}?mode=teacherview&examined_user_id=#{user_id}"
    end
  end

  def step_is_unreviewed_or_has_reviews?(review_count)
    review_count.nil? || review_count > 0
  end

  def collect_available_steps_with_id(peer_assessment_id)
    steps = api.rel(:steps).get(peer_assessment_id:).value!

    out = steps.map {|step| {step.id => step.type.split('::').last} }
    out.reduce({}, :update)
  end

  def collect_available_rubrics_with_id(peer_assessment_id)
    rubrics = api.rel(:rubrics).get(
      peer_assessment_id:,
      team_evaluation: false
    ).value!
    out = rubrics.map {|rubric| {rubric.id => rubric.title} }
    out = out.reduce({}, :update)
    out.sort_by {|_key, value| value }.to_h
  end

  def collect_available_steps(peer_assessment_id)
    steps = api.rel(:steps).get(peer_assessment_id:).value!
    steps.map {|step| step.type.split('::').last }
  end

  private

  attr_accessor :api_pa

  def api
    Xikolo.api(:peerassessment).value!
  end

  def unsubmitted_reviews?(reviews, submitted_reviews)
    # reviews.count == 1 and submitted_reviews.count == 0
    reviews.count - submitted_reviews.count > 0
  end
end

# rubocop:enable all
