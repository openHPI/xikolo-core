# frozen_string_literal: true

class PeerAssessment::ResultsController < PeerAssessment::BaseController
  include PeerAssessment::RegradingHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::RubricHelper
  include Collabspace::CollabspaceHelper

  inside_course
  inside_item
  inside_assessment

  before_action :load_rubrics, only: [:show_review]
  before_action :enable_teacherview, only: %i[show show_review]

  layout 'peer_assessment'

  def show
    # TODO: Remove Acfs
    Acfs.run

    Acfs.on the_assessment, the_steps do |assessment, steps|
      @grading_step  = steps.detect {|s| s.is_a? Xikolo::PeerAssessment::PeerGrading }
      @previous_step = steps[-2]

      user = account_api.rel(:user).get(id: @participant.user_id).value!
      @monitored_user = user['display_name']

      # There can only be one grading conflict
      @grading_conflict = pa_api.rel(:conflicts).get(
        reporter: @participant.user_id,
        peer_assessment_id: assessment.id,
        reason: 'grading_conflict'
      ).value&.first

      # Written reviews
      reviews = pa_api.rel(:reviews).get(
        user_id: @participant.user_id,
        submitted: true,
        step_id: @grading_step.id
      ).value || []

      @written_reviews = []
      reviews.each do |review|
        @written_reviews << PeerAssessment::ReviewPresenter.create(review)
      end

      # Received reviews
      submission = pa_api.rel(:submissions).get(
        peer_assessment_id: assessment.id,
        user_id: @participant.user_id,
        include_votes: true
      ).value!.first

      @grade = pa_api.rel(:grades).get(submission_id: submission.id).value&.first
      @nominations = submission['nominations']

      reviews = pa_api.rel(:reviews).get(
        step_id: @grading_step.id,
        submission_id: submission.id,
        submitted: true,
        with_team_submissions: true
      ).value || []

      @received_reviews = []
      reviews.each do |review|
        @received_reviews << PeerAssessment::ReviewPresenter.create(review)
      end
    end

    Acfs.run

    @regrading_possible_for_user = regrading_possible_for_user?(
      @current_step,
      @received_reviews,
      @grade,
      @grading_conflict
    )
    @regrading_possible = current_user.instrumented? || @regrading_possible_for_user
    # TODO: Remove Acfs
    @new_grading_conflict = Xikolo::PeerAssessment::Conflict.new if @regrading_possible
  end

  def show_review
    # TODO: Remove Acfs
    Acfs.run

    Acfs.on the_assessment do |assessment|
      review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:review_id]).to_s).value!
      @review = PeerAssessment::ReviewPresenter.create review
      @own_review = review.user_id == @participant.user_id

      submission = pa_api.rel(:submission).get(id: review['submission_id']).value!
      @submission = PeerAssessment::SubmissionPresenter.create submission
      # If it is not the own review, the submission must belong to the user
      if @own_review
        # TODO: Remove Acfs
        @reviewer = Xikolo::PeerAssessment::Participant.find_by(
          peer_assessment_id: assessment.id,
          user_id: review['user_id']
        )
      end
    end

    Acfs.run

    @rated = !@review.feedback_grade.nil?
    # TODO: Remove Acfs
    @new_conflict = Xikolo::PeerAssessment::Conflict.new

    if @own_review
      render 'show_own_review'
    end
  end

  def rate_review
    team_member_ids = team_members(the_course.id, current_user.id)

    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:review_id]).to_s).value!
    # A student can not rate his/her own reviews
    if review['user_id'] == current_user.id
      add_flash_message :error, I18n.t(:'peer_assessment.results.rating_authorization_error')
      return redirect_to peer_assessment_step_results_path
    end
    # Make sure that the correct review is getting rated

    # TODO: Remove Acfs
    Acfs.on the_course do
      submission = pa_api.rel(:submission).get(id: review['submission_id']).value!
      if submission['user_id'] != current_user.id && team_member_ids.exclude?(submission['user_id'])
        add_flash_message :error, I18n.t(:'peer_assessment.not_authorized')
        return redirect_to peer_assessment_path(params[:peer_assessment_id])
      end
    end

    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    check_availability

    rating = params[:rating].to_i

    if (rating > 4) || (rating < 0) || !@review.feedback_grade.nil?
      add_flash_message :error, I18n.t(:'peer_assessment.results.invalid_rating')
      return redirect_to review_result_peer_assessment_step_results_path
    end

    @review.feedback_grade = rating

    if @review.save
      add_flash_message :success, I18n.t(:'peer_assessment.results.rating_success')
    else
      add_flash_message :error, I18n.t(:'peer_assessment.results.rating_failure')
    end

    redirect_to review_result_peer_assessment_step_results_path
  end

  # This action is duplicated in the SubmissionManagementController.
  # It may be worth it to extract a reusable helper (class!) for the shared logic,
  # once this code is using direct database access.
  def request_regrading
    Acfs.on the_assessment, the_steps, the_participant do |assessment, steps, participant|
      @grading_step = steps.detect {|s| s.is_a? Xikolo::PeerAssessment::PeerGrading }

      # Check for an existing grading conflict
      @grading_conflict = Xikolo::PeerAssessment::Conflict.find_by(
        reporter: participant.user_id,
        peer_assessment_id: assessment.id,
        reason: 'grading_conflict'
      )

      submission = pa_api.rel(:submissions).get(
        peer_assessment_id: assessment.id,
        user_id: participant.user_id
      ).value!.first
      @grade = pa_api.rel(:grades).get(submission_id: submission.id).value&.first

      reviews = pa_api.rel(:reviews).get(
        step_id: @grading_step.id,
        submission_id: submission.id
      ).value || []

      @received_reviews = []
      reviews.each do |review|
        @received_reviews << PeerAssessment::ReviewPresenter.create(review)
      end
    end

    Acfs.run

    @regrading_possible = check_regrading_eligibility(@current_step, @received_reviews, @grade, @grading_conflict)

    unless @regrading_possible
      add_flash_message :error, I18n.t(:'peer_assessment.results.grading_conflict.not_eligible')
      return redirect_back fallback_location: root_path
    end

    # TODO: Remove Acfs
    @new_grading_conflict = Xikolo::PeerAssessment::Conflict.create!(
      reporter: @participant.user_id,
      reason: 'grading_conflict',
      peer_assessment_id: @assessment.id,
      comment: params[:xikolo_peer_assessment_conflict][:comment]
    )

    add_flash_message :success, I18n.t(:'peer_assessment.results.grading_conflict.success')

    redirect_back fallback_location: root_path
  end

  ### Report Conflict ###

  def report
    # TODO: remove Acfs
    @report = Xikolo::PeerAssessment::Conflict.new report_params
    @report.reporter = current_user.id
    @report.peer_assessment_id = UUID(params[:peer_assessment_id]).to_str

    subject_type = params[:xikolo_peer_assessment_conflict][:conflict_subject_type]

    if %w[Review PeerAssessment::ReviewPresenter].include?(subject_type)
      review = pa_api.rel(:review).get(id: params[:xikolo_peer_assessment_conflict][:conflict_subject_id]).value!
      @review = review
      @report.accused = review['user_id']
    end

    Acfs.run

    check_availability

    if @report.save
      add_flash_message :success, I18n.t(:'peer_assessment.review.report_submit')
    else
      add_flash_message :error, I18n.t(:'peer_assessment.review.report_failure')
    end

    redirect_to params[:origin]
  end

  private

  def report_params
    params.require('xikolo_peer_assessment_conflict').permit(
      :comment,
      :conflict_subject_id,
      :conflict_subject_type,
      :reason
    )
  end

  def check_availability
    if @current_step.deadline.past?
      add_flash_message :error, I18n.t(:'peer_assessment.results.deadline_passed')
      raise Status::Redirect.new 'Deadline passed', peer_assessment_step_results_path
    end
  end
end
