# frozen_string_literal: true

class PeerAssessment::TrainingController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::SubmissionHelper
  include PeerAssessment::ButtonsHelper

  inside_course
  inside_item
  inside_assessment except: [:autosave]

  before_action :load_rubrics, except: [:autosave]
  before_action :enable_teacherview, only: %i[evaluate new]

  layout 'peer_assessment'

  def new
    # TODO: Remove Acfs
    Acfs.run # Necessary because @current_step needs to be available first

    Acfs.on the_assessment, the_participant do |assessment|
      @statistic = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          user_id: @participant.user_id,
          peer_assessment_id: assessment.id,
          concern: 'student_training'
        )
      )

      # Retrieves a started training review or retrieves a new one
      review = pa_api.rel(:reviews).get(
        peer_assessment_id: assessment.id,
        as_student_training: true,
        user_id: @participant.user_id
      ).value&.first

      if review.nil? # May happen if the service encounters a closed training step
        add_flash_message :error, I18n.t(:'peer_assessment.training.no_samples_left')
        return redirect_to evaluate_peer_assessment_step_training_index_path(
          short_uuid(@assessment.id),
          short_uuid(@current_step.id)
        )
      else
        submission = submission_by_id review.submission_id
        @submission = PeerAssessment::SubmissionPresenter.create submission
        @review = PeerAssessment::ReviewPresenter.create review
      end
    end

    Acfs.run

    check_availability
    return render 'unavailable' unless @current_step.training_opened

    create_form_presenter
    create_skip_form
  end

  def update
    # TODO: Remove Acfs
    Acfs.on the_assessment do |assessment|
      @statistic = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          user_id: current_user.id,
          peer_assessment_id: assessment.id,
          concern: 'student_training'
        )
      )
      review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
      # TODO: PA introduce new roles and rights
      ensure_owner_or_permitted review, 'peerassessment.training_samples.manage'
      @review = PeerAssessment::ReviewPresenter.create review
      submission = submission_by_id review['submission_id']
      @submission = PeerAssessment::SubmissionPresenter.create submission
    end

    Acfs.run

    check_availability

    review = @review.review_form
    review.optionIDs = get_selected_options
    @errors = perform_update_checks(training: true)
    review.submitted = @errors[:messages].empty?

    if review.save
      if @errors[:messages].empty?
        add_flash_message :success, I18n.t(:'peer_assessment.review.submit_success')
        redirect_to evaluate_peer_assessment_step_training_index_path(
          short_uuid(@assessment.id),
          short_uuid(review.step_id)
        )
      else
        # Return with check errors
        add_flash_message :notice, I18n.t(:'peer_assessment.review.check_errors')
        create_form_presenter
        create_skip_form
        render 'new'
      end
    else
      add_flash_message :error, I18n.t(:'peer_assessment.review.server_error')
      create_form_presenter
      create_skip_form
      render 'new'
    end
  end

  def evaluate
    # Retrieve the respective TA reviews. Retrieve all training reviews of this
    # student, including submissions of the reviewees.
    @submissions = []
    @finished_reviews = []
    @ta_reviews = []

    # TODO: Remove Acfs
    Acfs.on the_assessment, the_steps, the_participant do
      reviews = pa_api.rel(:reviews).get(
        user_id: @participant.user_id,
        step_id: @current_step.id,
        train_review: false,
        submitted: true
      ).value!
      reviews.map do |review|
        Restify::Promise.new([
          pa_api.rel(:submission).get(id: review['submission_id']),
          pa_api.rel(:reviews).get(
            train_review: true,
            step_id: @current_step.id,
            submission_id: review['submission_id']
          ),
        ]) do |submission, ta_reviews|
          @finished_reviews << PeerAssessment::ReviewPresenter.create(review)
          submission = PeerAssessment::SubmissionPresenter.create submission
          @submissions << submission
          # Retrieve ta review
          @ta_reviews << ta_reviews.first
        end
      end.each(&:value!)
    end

    Acfs.run

    check_availability
    return render 'unavailable' unless @current_step.training_opened

    @passed = @current_step.deadline.past?
    @ta_reviews = @ta_reviews.map {|r| PeerAssessment::ReviewPresenter.create(r) }
    @optional = @current_step.optional

    @reviews = @finished_reviews.zip @submissions, @ta_reviews

    unsubmitted_drafts = pa_api.rel(:reviews).get(
      user_id: @participant.user_id,
      step_id: @current_step.id,
      train_review: false,
      submitted: false
    ).value!
    @first_entering = true if @finished_reviews.empty? && unsubmitted_drafts.empty? && !@passed

    if @optional || (@current_step.step.required_reviews <= @finished_reviews.count)
      @continue = true
      @next_step = @step_presenters[@step_presenters.index(@current_step) + 1]
      @additional_sample = true unless @passed
      @continue_button_enabled = true unless @next_step.unlock_date.try(:future?) || @teacherview
    elsif @passed
      redirect_to deadline_passed_peer_assessment_step_path id: short_uuid(@current_step.id)
    else
      @next_sample = true
    end
  end
  # rubocop:enable all

  def autosave
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    # TODO: PA introduce new roles and rights
    ensure_owner_or_permitted review, 'peerassessment.training_samples.manage'
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    @review.optionIDs = get_selected_options

    if @review.save
      render json: {success: true, timestamp: Time.zone.now}
    else
      render json: {success: false}
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
    if (params[:action] != 'evaluate') && (params[:action] != 'advance')
      raise Status::Redirect.new(
        'This action is no longer available',
        evaluate_peer_assessment_step_training_index_path(
          short_uuid(@assessment.id),
          short_uuid(@current_step.id)
        )
      )
    end
  end

  def check_availability
    # If the user already progressed to the next step, he is no longer able to create training reviews.

    create_skip_form
    if @participant.current_step != @current_step.id
      @resume = true

      if params[:action] != 'evaluate'
        redirect_to evaluate_peer_assessment_step_training_index_path(
          short_uuid(@assessment.id),
          short_uuid(@current_step.id)
        )
      end
    end
  end

  def create_form_presenter
    @form_presenter = PeerAssessment::ReviewFormPresenter.create(@assessment, @review, 'student_training')
    @form_presenter.confirm_title   = I18n.t(:'peer_assessment.training.confirmation_title')
    @form_presenter.confirm_message = I18n.t(:'peer_assessment.training.confirmation_message')
    @form_presenter.small_buttons   = true
    @form_presenter.small_headlines = true
    @form_presenter.enable_qualitative_feedback = false
  end

  def create_skip_form
    @skip_form = {
      advance_path: advance_peer_assessment_step_training_index_path(@assessment.id, @current_step.id),
        confirm_button: I18n.t(:'peer_assessment.training.advance_confirmation.confirm_button'),
        cancel_button: I18n.t(:'peer_assessment.training.advance_confirmation.cancel_button'),
        confirm_title: I18n.t(:'peer_assessment.training.advance_confirmation.title'),
        confirm_message: I18n.t(:'peer_assessment.training.advance_confirmation.text'),
    }
  end
end
