# frozen_string_literal: true

class PeerAssessment::PeerAssessmentsController < PeerAssessment::BaseController
  include Collabspace::CollabspaceHelper

  inside_course only: %i[show index edit update files upload remove_file]
  inside_item only: [:show]
  inside_assessment_skip_checks only: %i[show start_assessment]

  skip_before_action :set_js_data, only: :index
  skip_before_action :set_pa_id, only: :index
  skip_before_action :load_peer_assessment, only: :index

  # For the progress tab peer assessment overview
  def index
    authorize! 'peerassessment.peerassessment.index'

    course = ::Course::Course.by_identifier(params[:course_id]).take!
    assessments = []
    Xikolo.paginate(pa_api.rel(:peer_assessments).get(course_id: course.id)) do |assessment|
      assessments << assessment
    end
    @assessments = create_assessment_presenters(assessments)
    Acfs.run

    @assessments.sort!

    render 'admin_index', layout: 'course_area'
  end

  def show
    Acfs.run

    # users that are not in a collabspace team cannot access the peer assessment
    if @assessment.is_team_assessment && team_members(@assessment.course_id, current_user.id).empty?
      return render 'peer_assessment_team'
    end

    # Check for an existing participant object, which is an indicator that the
    # user already started the peer assessment (or at least clicked it). If not
    # present, create a fresh user addition for the requesting user.
    if @participant.nil?
      # For Team peer assessments make sure every team member is a participant
      # and they are in a group
      if @assessment.is_team_assessment

        # TODO: remove Acfs
        group = Xikolo::PeerAssessment::Group.create nil
        team_members(@assessment.course_id, current_user.id).each do |user_id|
          # TODO: remove Acfs
          participant = Xikolo::PeerAssessment::Participant.create(
            user_id:,
            peer_assessment_id: @assessment.id,
            group_id: group.id
          )

          @participant = participant if participant.user_id == current_user.id
        end
      else
        # TODO: remove Acfs
        @participant = Xikolo::PeerAssessment::Participant.create(
          user_id: current_user.id,
          peer_assessment_id: @assessment.id
        )
      end
    end

    # Resume the peer assessment process if started already.
    if @participant.current_step
      return redirect_to peer_assessment_step_url(
        short_uuid(@assessment.id),
        short_uuid(@participant.current_step)
      )
    end

    unless @step_presenters.first
      set_page_title @assessment.title, I18n.t(:'peer_assessment.under_construction.header')
      return render 'under_construction'
    end

    set_page_title the_course.title, @assessment.title

    if @step_presenters.first.open?
      render layout: 'peer_assessment'
    elsif @step_presenters.first.unlock_date.try(:future?)
      render 'peer_assessment_locked', layout: 'peer_assessment'
    else
      render 'peer_assessment_passed', layout: 'peer_assessment'
    end
  end

  def start_assessment
    begin
      Acfs.run
    rescue
      return redirect_to peer_assessment_path short_uuid(the_assessment.id)
    end

    if params.key?(:coh_ack) && (params[:coh_ack] == 'on')
      advance
    else
      add_flash_message :error, I18n.t(:'peer_assessment.ack_error')
      redirect_to peer_assessment_path short_uuid(the_assessment.id)
    end
  end

  def edit
    authorize! 'peerassessment.peerassessment.view'

    # TODO: remove Acfs
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find(
      UUID(params[:id]),
      params: {raw: true}
    ) do |assessment|
      @assessment_presenter = PeerAssessment::PeerAssessmentEditPresenter.new(
        peer_assessment: assessment
      )
    end

    Acfs.run

    @active_tab = :general

    render layout: 'edit_peer_assessment_layout'
  end

  def update
    authorize! 'peerassessment.peerassessment.edit'

    # TODO: remove Acfs
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:id])
    Acfs.run

    @assessment.attributes = update_params
    @active_tab = :general

    if @assessment.save
      add_flash_message :success, I18n.t(:'peer_assessment.administration.save_success')
      redirect_to edit_peer_assessment_path(short_uuid(@assessment.id))
    else
      add_flash_message :error, I18n.t(:'peer_assessment.administration.save_failure')
      render 'edit', layout: 'edit_peer_assessment_layout'
    end
  end

  def files
    authorize! 'peerassessment.peerassessment.view'

    # TODO: remove Acfs
    @assessment = Xikolo::PeerAssessment::PeerAssessment.find UUID(params[:id])

    Acfs.run

    @file_upload = FileUpload.new purpose: :peerassessment_assessment_attachment

    @active_tab = :files
    render layout: 'edit_peer_assessment_layout'
  end

  def upload
    authorize! 'peerassessment.peerassessment.edit'

    assessment = pa_api.rel(:peer_assessment)
      .get(id: UUID(params[:id]).to_s).value!

    registration = assessment.rel(:files).post(
      upload_uri: params.require(:upload_uri),
      user_id: current_user.id
    )

    if registration.value
      render json: {
        success: true,
        upload: registration.value,
      }
    else
      render json: {
        success: false,
        error: I18n.t(:'peer_assessment.administration.file_upload_failed'),
      }, status: :internal_server_error
    end
  end

  def remove_file
    authorize! 'peerassessment.peerassessment.edit'

    assessment = pa_api.rel(:peer_assessment)
      .get(id: UUID(params[:peer_assessment_id]).to_s).value!
    assessment.rel(:file).delete(id: params[:file_id]).value!

    render json: {success: true}
  rescue Restify::ResponseError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    render json: {success: false, message: I18n.t(:'peer_assessment.submission.file_delete_failed')}
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

  def hide_course_nav?
    # Only show the course nav in the learner-facing page (the show page)
    @_action_name != 'show'
  end

  private

  def create_assessment_presenters(assessments)
    assessments.filter_map do |assessment|
      item = ::Course::Item.find(assessment['item_id'])
      Restify::Promise.new([
        pa_api.rel(:statistics).get(
          peer_assessment_id: assessment['id'],
          concern: 'assessment_statistic'
        ),
        pa_api.rel(:steps).get(
          peer_assessment_id: assessment['id']
        ),
        pa_api.rel(:submissions).get(
          user_id: current_user.id,
          peer_assessment_id: assessment['id']
        ),
      ]) do |statistic, steps, submission|
        PeerAssessment::PeerAssessmentPresenter.new(
          peer_assessment: assessment,
          submission:,
          section: item.section,
          steps:,
          statistic:
        )
      end
    rescue ActiveRecord::RecordNotFound
      # Skip peer assessments for a deleted course item / section
      # (content resources are not yet reliably cleaned up).
    end.filter_map do |promise|
      promise.value!
    rescue Restify::ClientError
      # Skip peer assessments with missing / invalid data.
    end
  end

  def update_params
    params.require(:xikolo_peer_assessment_peer_assessment).permit(
      :allow_gallery_opt_out,
      :allowed_attachments,
      :allowed_file_types,
      :grading_hints,
      :instructions,
      :is_team_assessment,
      :item_id,
      :max_file_size,
      :title,
      :usage_disclaimer
    )
  end
end
