# frozen_string_literal: true

class PeerAssessment::TrainSamplesController < PeerAssessment::BaseController
  include PeerAssessment::RubricHelper
  include PeerAssessment::ReviewHelper
  include PeerAssessment::SubmissionHelper

  inside_course

  before_action { authorize! 'peerassessment.training_samples.manage' }
  before_action :load_rubrics, only: %i[new edit update]
  before_action :load_assessment, except: [:autosave]
  before_action :load_training_step, except: [:autosave]

  def index
    # Number of required train samples and current count of train samples
    # TODO Remove Acfs
    Acfs.on the_assessment do |assessment|
      @train_stats = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          peer_assessment_id: assessment.id,
          concern: 'training'
        )
      )
      @train_reviews = pa_api.rel(:reviews).get(
        train_review: true,
        peer_assessment_id: assessment.id
      ).value || []
    end

    Acfs.run

    create_review_presenters
  end

  def new
    # Get a review with a submission chosen by the service
    # # TODO Remove Acfs
    Acfs.on the_assessment do |assessment|
      review = pa_api.rel(:reviews).get(
        peer_assessment_id: assessment.id,
        as_train_sample: true,
        user_id: current_user.id
      ).value&.first

      if review.nil?
        add_flash_message :notice, I18n.t(:'peer_assessment.train_samples.no_samples')
        return redirect_to peer_assessment_train_samples_path
      end

      submission = submission_by_id review['submission_id']
      @submission = PeerAssessment::SubmissionPresenter.create submission

      @review = PeerAssessment::ReviewPresenter.create review
    end

    create_form_presenter
    redirect_to action: :edit, id: short_uuid(@review.id)
  end

  def edit
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    submission = submission_by_id review['submission_id']
    @submission = PeerAssessment::SubmissionPresenter.create submission
    @review = PeerAssessment::ReviewPresenter.create review

    # TODO: Remove Acfs
    the_assessment

    Acfs.run

    create_form_presenter

    if @training_step.training_opened
      # Abort
      redirect_to peer_assessment_train_samples_path
    end
  end

  def update
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    @review = PeerAssessment::ReviewPresenter.create review
    submission = submission_by_id review['submission_id']
    @submission = PeerAssessment::SubmissionPresenter.create submission

    # TODO: Remove Acfs
    the_assessment

    Acfs.run

    create_form_presenter

    if @training_step.training_opened
      # Abort
      add_flash_message :notice, I18n.t(:'peer_assessment.train_samples.training_open_error')
      return redirect_to peer_assessment_train_samples_path
    end

    review = @review.review_form

    # Set attributes
    review.text = params[:xikolo_peer_assessment_review][:text]
    review.optionIDs = get_selected_options

    # Update checks
    @errors = perform_update_checks training: true

    if @errors[:messages].empty?
      review.submitted = true
    else
      # If someone decides to mess with the params... I.e. if a rubric is
      # selected, then it should not be possible to change it to nothing without
      # changing the html/params
      review.submitted = false
    end

    if review.save
      if @errors[:messages].empty?
        # Redirect to overview
        add_flash_message :success, I18n.t(:'peer_assessment.review.submit_success')
        redirect_to peer_assessment_train_samples_path @assessment
      else
        # Render edit with check error
        add_flash_message :notice, I18n.t(:'peer_assessment.review.check_errors')
        render 'edit'
      end
    else
      # Render edit with save error
      add_flash_message :error, I18n.t(:'peer_assessment.review.server_error')
      render 'edit'
    end
  end

  def destroy
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    if @training_step.training_opened
      # Abort
      return redirect_to peer_assessment_train_samples_path
    end

    if @review.delete
      add_flash_message :success, 'Review deleted'
    else
      add_flash_message :error, 'Failed to delete review. If this error persists, please contact the helpdesk.'
    end

    redirect_to peer_assessment_train_samples_path
  end

  def autosave
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    @review.text = params[:xikolo_peer_assessment_review][:text]
    @review.optionIDs = get_selected_options

    if @review.save
      render json: {success: true, timestamp: Time.zone.now}
    else
      render json: {success: false}
    end
  end

  def open_training
    # TODO: Remove Acfs
    Acfs.on the_assessment do |assessment|
      @train_stats = PeerAssessment::StatisticsPresenter.create(
        Xikolo::PeerAssessment::Statistic.find(
          peer_assessment_id: assessment.id,
          concern: 'training'
        )
      )
    end

    Acfs.run

    if @train_stats.training_available?

      # Do not use training_opened here!
      # TODO: And why?
      @training_step.training_opened = true

      if @training_step.save
        # Back to the assessment overview page
        add_flash_message :success, I18n.t(:'peer_assessment.train_samples.open_success')
        return redirect_to course_peer_assessments_path @assessment.course_id
      else
        # Show error and redirect to the train sample overview page
        add_flash_message :error, I18n.t(:'peer_assessment.train_samples.open_error')
        return redirect_to peer_assessment_train_samples_path short_uuid(@assessment)
      end
    end

    redirect_to peer_assessment_train_samples_path short_uuid(@assessment)
  end

  def extend_deadline
    review = pa_api.rel(:review).get(id: UUID4.try_convert(params[:id]).to_s).value!
    @review = PeerAssessment::ReviewForm.new(review)

    Acfs.run

    extend_review_deadline @review
    redirect_to params[:origin]
  end

  private

  def create_review_presenters
    @review_presenters = []

    @train_reviews.each do |review|
      @review_presenters.push PeerAssessment::ReviewPresenter.create(review)
    end
  end

  def create_form_presenter
    @form_presenter = PeerAssessment::ReviewFormPresenter.create(@assessment, @review, 'training_sample')
    @form_presenter.confirm_title = I18n.t(:'peer_assessment.train_samples.submit_message_title')
    @form_presenter.confirm_message = I18n.t(:'peer_assessment.train_samples.submit_message')
    @form_presenter.small_buttons = true
    @form_presenter.small_headlines = true
    @form_presenter.text_required = false
  end
end
