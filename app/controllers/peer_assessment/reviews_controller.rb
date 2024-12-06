# frozen_string_literal: true

class PeerAssessment::ReviewsController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::SubmissionHelper

  inside_course except: %i[autosave extend_deadline]
  inside_item except: %i[autosave extend_deadline]
  inside_assessment except: %i[autosave extend_deadline]

  before_action :load_rubrics, except: %i[autosave extend_deadline advance]
  before_action :enable_teacherview, only: %i[show index]

  layout 'peer_assessment'

  def index
    # TODO: remove Acfs
    Acfs.on the_assessment, the_steps, the_participant do |assessment|
      @statistic = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          user_id: @participant.user_id,
          peer_assessment_id: assessment.id,
          concern: 'student_grading'
        )
      )

      Restify::Promise.new([
        pa_api.rel(:reviews).get(
          user_id: @participant.user_id,
          peer_assessment_id: assessment.id,
          step_id: @current_step.id
        ),
        account_api.rel(:user).get(id: @participant.user_id),
      ]) do |reviews, user|
        @review_presenters = []
        reviews.each do |review|
          @review_presenters << PeerAssessment::ReviewPresenter.create(review)
        end

        @monitored_user = user['display_name']
      end.value!
    end

    Acfs.run

    # The user is no longer able to create or edit reviews, if:
    # 1. The user already progressed to the next step (checked in
    #    check_availability)
    # 2. The deadline already passed (via @passed flag) However, the user will
    #    be able to advance as long as he fulfills the preconditions

    # If the user can resume, check_availability will set the @resume flag
    check_availability

    # If there is an unsubmitted review:
    @continue_grading = @review_presenters.detect {|p| !p.submitted && !p.suspended }
    @passed = @current_step.deadline.past?

    # If the user can continue the process (additional reviews can be ignored
    # and will be destroyed on the next step enter):
    if @statistic.reviews_left == 0
      @continue = true
      @next_step = @step_presenters[@step_presenters.index(@current_step) + 1]
    elsif @passed
      redirect_to deadline_passed_peer_assessment_step_path id: short_uuid(@current_step.id)
    end
  end

  def show
    # TODO: remove Acfs
    Acfs.on the_assessment do |_assessment|
      review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!

      submission = submission_by_id review['submission_id']
      @submission = PeerAssessment::SubmissionPresenter.create submission
      # TODO: PA introduce new roles and rights
      ensure_owner_or_permitted review, 'peerassessment.submission.inspect'
      @review = PeerAssessment::ReviewPresenter.create review
    end

    Acfs.run
  end

  def new
    # Get a review with a submission chosen by the service
    # TODO remove Acfs
    Acfs.on the_assessment, the_participant, the_steps do |assessment|
      # Determine availability and abort if necessary
      check_availability
      review = pa_api.rel(:reviews).get(
        peer_assessment_id: assessment.id,
        as_peer_grading: true,
        user_id: @participant.user_id
      ).value&.first

      if review.nil?
        add_flash_message :notice, I18n.t(:'peer_assessment.review.no_grading_samples_available')
        return redirect_to peer_assessment_step_reviews_path(
          params[:peer_assessment_id],
          params[:step_id]
        )
      end

      submission =  pa_api.rel(:submission).get(id: review['submission_id']).value!
      @submission = PeerAssessment::SubmissionPresenter.create submission
      # Retrieved review
      @review = PeerAssessment::ReviewPresenter.create review
    end

    Acfs.run

    # TODO: remove Acfs
    @new_conflict = Xikolo::PeerAssessment::Conflict.new
    create_form_presenter
  end

  def edit
    # TODO: remove Acfs
    Acfs.on the_assessment do |assessment|
      if params[:revision]
        @statistic = PeerAssessment::StatisticsPresenter.create(
          Xikolo::PeerAssessment::Statistic.find(
            user_id: current_user.id,
            peer_assessment_id: assessment.id,
            concern: 'student_grading'
          )
        )
      end

      review = pa_api.rel(:reviews).get(
        review_id: UUID4.try_convert(params[:id]).to_s,
        raw: true
      ).value&.first

      # Avoid giving the participant a 404 screen when his or her review has
      # been trashed in the background
      if review.nil?
        add_flash_message :info, I18n.t(:'peer_assessment.review.review_deleted')
        return redirect_to peer_assessment_step_reviews_path
      end

      submission = submission_by_id review['submission_id']
      @submission = PeerAssessment::SubmissionPresenter.create submission

      # TODO: PA introduce new roles and rights
      ensure_owner_or_permitted review, 'peerassessment.review.edit'
      @review = PeerAssessment::ReviewPresenter.create review
    end

    Acfs.run

    check_availability
    create_form_presenter

    if params[:revision] && (params[:revision] == 'true')
      unless @review.submitted
        add_flash_message :error, I18n.t(:'peer_assessment.review.not_revisable')
        return redirect_to peer_assessment_step_reviews_path(
          short_uuid(@assessment.id),
          short_uuid(@current_step.id)
        )
      end

      # We do not want autosave here, since we do not want unintentional,
      # unnoticed changes while the user is briefly skimming through his reviews
      @form_presenter.enable_autosave = false

    elsif @review.submitted
      # Abort
      add_flash_message :error, I18n.t(:'peer_assessment.review.not_editable')
      return redirect_to peer_assessment_step_reviews_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    end

    @new_conflict = Xikolo::PeerAssessment::Conflict.new
    render 'new'
  end

  def update
    Acfs.on the_assessment do |assessment|
      @statistic = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          user_id: current_user.id,
          peer_assessment_id: assessment.id,
          concern: 'student_grading'
        )
      )
      review = pa_api.rel(:reviews).get(
        review_id: UUID4.try_convert(params[:id]).to_s
      ).value&.first

      if review.nil?
        add_flash_message :error, I18n.t(:'peer_assessment.review.review_deleted')
        return redirect_to peer_assessment_step_reviews_path
      end

      # TODO: PA introduce new roles and rights
      ensure_owner_or_permitted review, 'peerassessment.review.edit'
      @review = PeerAssessment::ReviewPresenter.create review
      submission = submission_by_id review['submission_id']
      @submission = PeerAssessment::SubmissionPresenter.create submission
    end

    Acfs.run

    check_availability

    review = @review.review_form
    review.optionIDs = get_selected_options
    review.text  = params[:xikolo_peer_assessment_review][:text]
    review.award = params[:xikolo_peer_assessment_review][:award]

    @errors = perform_update_checks
    review.submitted = @errors[:messages].empty?

    if review.save
      if @errors[:messages].empty?
        add_flash_message :success, I18n.t(:'peer_assessment.review.submit_success')
        redirect_to peer_assessment_step_reviews_path(
          short_uuid(@assessment.id),
          short_uuid(review.step_id)
        )
      else
        # Return with check errors
        add_flash_message :notice, I18n.t(:'peer_assessment.review.check_errors')
        create_form_presenter
        # TODO: remove Acfs
        @new_conflict = Xikolo::PeerAssessment::Conflict.new
        render 'peer_assessment/reviews/new'
      end
    else
      add_flash_message :error, I18n.t(:'peer_assessment.review.server_error')
      create_form_presenter
      # TODO: remove Acfs
      @new_conflict = Xikolo::PeerAssessment::Conflict.new
      render 'peer_assessment/reviews/new'
    end
  end

  def autosave
    review = pa_api.rel(:review).get(
      id: UUID4.try_convert(params[:id]).to_s
    ).value!

    # TODO: PA introduce new roles and rights
    ensure_owner_or_permitted review, 'peerassessment.review.edit'
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    @review.optionIDs = get_selected_options
    @review.text  = params[:xikolo_peer_assessment_review][:text]
    @review.award = params[:xikolo_peer_assessment_review][:award]

    if @review.save && !@review.submitted
      render json: {success: true, timestamp: Time.zone.now}
    else
      render json: {success: false}
    end
  rescue Restify::NotFound # Reviews may have been cleaned up, even if they're still open in a browser
    render json: {success: false}
  end

  def extend_deadline
    review = pa_api.rel(:review).get(
      id: UUID4.try_convert(params[:id]).to_s
    ).value!

    # TODO: PA introduce new roles and rights
    ensure_owner_or_permitted review, 'peerassessment.review.edit'
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    extend_review_deadline @review
    redirect_to params[:origin]
  end

  ### Report Submission ###

  def report
    @submission = pa_api.rel(:submission).get(
      id: params[:xikolo_peer_assessment_conflict][:conflict_subject_id]
    ).value!

    Acfs.run

    check_availability

    # TODO: Remove Acfs
    report = Xikolo::PeerAssessment::Conflict.new report_params
    report.reporter = current_user.id
    report.accused  = @submission['user_id']
    report.peer_assessment_id = @assessment.id

    if report.save
      add_flash_message :success, I18n.t(:'peer_assessment.review.report_submit')
      redirect_to peer_assessment_step_reviews_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    else
      add_flash_message :error, I18n.t(:'peer_assessment.review.report_failure')
      redirect_to params[:origin]
    end
  end

  def advance
    Acfs.run unless the_participant.loaded?

    if @participant.save(params: {update_type: 'advance'})
      redirect_to peer_assessment_path short_uuid(the_assessment.id)
    else
      @participant.errors.messages[:base].each do |msg|
        add_flash_message :error, I18n.t(:"peer_assessment.advancement.errors.#{msg}")
      end
    end
  end

  private

  # Override check method to do nothing
  def handle_deadline_passed
    if %w[edit update autosave report new extend_deadline].include? params[:action]
      raise Status::Redirect.new(
        'This action is no longer available',
        peer_assessment_step_reviews_path(
          short_uuid(@assessment.id),
          short_uuid(@current_step.id)
        )
      )
    end
  end

  def check_availability
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
    @form_presenter = PeerAssessment::ReviewFormPresenter.create(
      @assessment,
      @review,
      'regular_review'
    )
    @form_presenter.small_buttons    = true
    @form_presenter.small_headlines  = true
    @form_presenter.enable_awards    = true
    @form_presenter.enable_reporting = true
    @form_presenter.show_bottom_info = true
  end

  def report_params
    params.require('xikolo_peer_assessment_conflict').permit(
      :comment,
      :conflict_subject_id,
      :conflict_subject_type,
      :reason
    )
  end
end
