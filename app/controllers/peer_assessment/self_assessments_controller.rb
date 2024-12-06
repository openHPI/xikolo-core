# frozen_string_literal: true

class PeerAssessment::SelfAssessmentsController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::SubmissionHelper
  include PeerAssessment::ButtonsHelper

  inside_course except: [:autosave]
  inside_item except: [:autosave]
  inside_assessment

  before_action :load_rubrics, except: [:autosave]
  before_action :enable_teacherview, only: [:show]

  layout 'peer_assessment'

  def show
    # TODO: remove Acfs
    Acfs.run
    Acfs.on the_assessment, the_steps, the_participant do |assessment, _steps, _participant|
      review = pa_api.rel(:reviews).get(
        user_id: @participant.user_id,
        step_id: @current_step.id
      ).value&.first
      if review.nil?
        Rails.logger.debug 'REDIRECT: Self assessment not existing'
        return redirect_to new_peer_assessment_step_self_assessments_path
      end

      @review = PeerAssessment::ReviewPresenter.create review
      submission = fetch_submission(owner: false, user_id: @participant.user_id)
      @submission = PeerAssessment::SubmissionPresenter.create submission

      @team_evaluation_rubrics = Xikolo::PeerAssessment::Rubric.where(
        peer_assessment_id: assessment.id,
        team_evaluation: true
      ) do |rubrics|
        rubrics.each(&:options!)
        unless rubrics.empty?
          @team_evaluation_reviews = pa_api.rel(:reviews).get(
            user_id: @participant.user_id,
            peer_assessment_id: assessment.id,
            step_id: @current_step.id,
            as_team_evaluation: true
          ).value!

          @team_evaluation_reviews.each do |rev|
            submission = pa_api.rel(:submission).get(id: rev['submission_id']).value!
            user = Xikolo.api(:account).value!.rel(:user).get(id: submission['user_id']).value!
            rev.merge!(submission:, submission_user: user)
          end
        end
      end
    end

    Acfs.run

    if @submission.nil?
      add_flash_message :error, I18n.t(:'peer_assessment.submission.not_found')
      redirect_to peer_assessment_error_path short_uuid(@assessment.id)
    elsif !@review.submitted && (@current_step.id == @participant.current_step)
      redirect_to new_peer_assessment_step_self_assessments_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    end

    create_form_presenter
    create_skip_form
  end

  def new
    # Check if there is already a self assessment
    # TODO: remove Acfs
    Acfs.on the_assessment, the_steps, the_participant do |assessment, _steps, _participant|
      review = pa_api.rel(:reviews).get(
        user_id: current_user.id,
        peer_assessment_id: assessment.id,
        step_id: @current_step.id,
        as_self_assessment: true
      ).value&.first

      submission = fetch_submission
      @submission = PeerAssessment::SubmissionPresenter.create submission
      @review = PeerAssessment::ReviewPresenter.create review

      @team_evaluation_rubrics = Xikolo::PeerAssessment::Rubric.where(
        peer_assessment_id: assessment.id,
        team_evaluation: true
      ) do |rubrics|
        rubrics.each(&:options!)
        unless rubrics.empty?
          @team_evaluation_reviews = pa_api.rel(:reviews).get(
            user_id: current_user.id,
            peer_assessment_id: assessment.id,
            step_id: @current_step.id,
            as_team_evaluation: true
          ).value
          # Maybe there is a better way?
          @team_evaluation_reviews.each do |rev|
            submission = pa_api.rel(:submission).get(id: rev['submission_id']).value!
            user = Xikolo.api(:account).value!.rel(:user).get(id: submission['user_id']).value!
            rev.merge!(submission:, submission_user: user)
          end
        end
      end
    end

    Acfs.run

    if @review.nil?
      add_flash_message :error, I18n.t(:'peer_assessment.submission.server_error')
      redirect_to peer_assessment_error_path short_uuid(@assessment.id)
    elsif @review.submitted
      add_flash_message :notice, I18n.t(:'peer_assessment.self_assessment.already_submitted')
      return redirect_to peer_assessment_step_self_assessments_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    end

    create_form_presenter
    create_skip_form
  end

  def update
    # TODO: remove Acfs
    Acfs.on the_assessment, the_steps do |assessment, _steps|
      review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!

      # TODO: PA introduce new roles and rights
      ensure_owner_or_permitted review, 'peerassessment.review.edit'
      @review = PeerAssessment::ReviewPresenter.create review
      @team_evaluation_rubrics = Xikolo::PeerAssessment::Rubric.where(
        peer_assessment_id: assessment.id,
        team_evaluation: true
      ) do |rubrics|
        unless rubrics.empty?
          @team_evaluation_reviews = pa_api.rel(:reviews).get(
            user_id: current_user.id,
            peer_assessment_id: assessment.id,
            step_id: @current_step.id,
            as_team_evaluation: true
          ).value
        end
      end
      submission = fetch_submission
      @submission = PeerAssessment::SubmissionPresenter.create submission
    end

    Acfs.run

    check_availability

    review = @review.review_form
    review.optionIDs = get_selected_options
    @errors = perform_update_checks

    unless @errors[:messages].empty?
      add_flash_message :notice, I18n.t(:'peer_assessment.review.check_errors')
      redirect_to peer_assessment_step_path params[:peer_assessment_id], params[:step_id]
      return false
    end

    review.submitted = true

    save_team_evaluation_reviews(submit: true)

    unless review.save
      add_flash_message :error, I18n.t(:'peer_assessment.review.server_error')
    end

    advance
  end

  def autosave
    review = pa_api.rel(:review).get(
      id: UUID4.try_convert(params[:id]).to_s
    ).value!

    # TODO: PA introduce new roles and rights
    ensure_owner_or_permitted review, 'peerassessment.review.edit'
    # TODO: remove Acfs
    Acfs.on the_assessment, the_steps do |assessment, _steps|
      @team_evaluation_rubrics = Xikolo::PeerAssessment::Rubric.where(
        peer_assessment_id: assessment.id,
        team_evaluation: true
      ) do |rubrics|
        unless rubrics.empty?
          @team_evaluation_reviews = pa_api.rel(:reviews).get(
            user_id: current_user.id,
            peer_assessment_id: assessment.id,
            step_id: @current_step.id,
            as_team_evaluation: true
          ).value
        end
      end
    end
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    @review.optionIDs = get_selected_options

    save_team_evaluation_reviews

    if @review.save && !@review.submitted
      render json: {success: true, timestamp: Time.zone.now}
    else
      render json: {success: false}
    end
  end

  def advance
    Acfs.run unless the_participant.loaded?

    if @participant.save(params: {update_type: 'advance'})
      redirect_to peer_assessment_path short_uuid(the_assessment.id)
      add_flash_message :success, I18n.t(:'peer_assessment.review.submit_success')
    else
      @participant.errors.messages[:base].each do |msg|
        add_flash_message :error, I18n.t(:"peer_assessment.advancement.errors.#{msg}")
      end
      add_flash_message :error, I18n.t(:'peer_assessment.review.server_error')
      redirect_to peer_assessment_step_path params[:peer_assessment_id], params[:step_id]
    end
  end

  private

  def check_availability
    # If the user already progressed to the next step, he is no longer able to create training reviews
    if @participant.current_step != @current_step.id
      @resume = true

      if params[:action] != 'index'
        raise Status::Redirect.new(
          'This action is no longer available',
          peer_assessment_step_reviews_path(
            short_uuid(@assessment.id),
            short_uuid(@current_step.id)
          )
        )
      end
    end
  end

  def create_form_presenter
    @form_presenter = PeerAssessment::ReviewFormPresenter.create(@assessment, @review, 'self_assessment')
    @form_presenter.small_headlines  = true
    @form_presenter.enable_awards    = false
    @form_presenter.enable_reporting = false
    @form_presenter.confirm_title    = I18n.t('peer_assessment.self_assessment.confirm_title')
    @form_presenter.confirm_message  = I18n.t('peer_assessment.self_assessment.confirm_message')
    @form_presenter.submit_button_text = I18n.t('peer_assessment.self_assessment.submit_button')
    @form_presenter.enable_qualitative_feedback = false
    @form_presenter.is_optional =
      Xikolo.api(:peerassessment).value!.rel(:step).get(id: @review.step_id).value!['optional']
  end

  def create_skip_form
    @skip_form = {
      advance_path: advance_peer_assessment_step_self_assessments_path(@assessment.id, @current_step.id),
      confirm_button: I18n.t(:'peer_assessment.self_assessment.advance_confirmation.confirm_button'),
      cancel_button: I18n.t(:'peer_assessment.self_assessment.advance_confirmation.cancel_button'),
      confirm_title: I18n.t(:'peer_assessment.self_assessment.advance_confirmation.title'),
      confirm_message: I18n.t(:'peer_assessment.self_assessment.advance_confirmation.text'),
    }
  end

  def save_team_evaluation_reviews(submit: false)
    # structure of team evaluation params:
    # "team_evaluation_#{review.id}_#{rubric.id}"
    return if @team_evaluation_reviews.nil?

    @team_evaluation_reviews.each do |team_review|
      team_review = PeerAssessment::ReviewForm.new(team_review)
      team_review.optionIDs = []
      @team_evaluation_rubrics.each do |rubric|
        option_id = params[:"team_evaluation_#{team_review.id}_#{rubric.id}"]
        next if option_id.blank?

        team_review.optionIDs << option_id
      end

      if submit
        team_review.submitted = true
      end

      team_review.save
    end
  end
end
# rubocop:enable all
