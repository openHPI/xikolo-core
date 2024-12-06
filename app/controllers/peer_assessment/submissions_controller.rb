# frozen_string_literal: true

class PeerAssessment::SubmissionsController < PeerAssessment::BaseController
  include PeerAssessment::SubmissionHelper
  include Collabspace::CollabspaceHelper

  inside_course only: %i[show new additional_attempt additional_attempt_update remove_file]
  inside_item only: %i[show new additional_attempt additional_attempt_update]
  inside_assessment only: %i[show new update upload additional_attempt additional_attempt_update]

  layout 'peer_assessment'

  skip_before_action :set_js_data, only: %i[upload remove_file]

  before_action :enable_teacherview, only: [:show]

  def show
    @user, @submission = load_user_and_submission
    Acfs.run

    @submission = PeerAssessment::SubmissionPresenter.create @submission

    if @submission.nil?
      add_flash_message :error, I18n.t(:'peer_assessment.submission.not_found')
      redirect_to peer_assessment_error_path short_uuid(@assessment.id)
    elsif !@submission.submitted && (@current_step.id == @participant.current_step)
      redirect_to new_peer_assessment_step_submission_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    end
  end

  def new
    @user, @submission = load_user_and_submission
    Acfs.run

    @file_upload = FileUpload.new(
      purpose: :peerassessment_submission_attachment,
      size: (0..the_assessment.max_file_size * 1024 * 1024)
    )

    if @submission.nil?
      add_flash_message :error, I18n.t(:'peer_assessment.submission.server_error')
      redirect_to peer_assessment_error_path short_uuid(@assessment.id)
    elsif @submission['submitted'] || (@current_step.id != @participant.current_step)
      add_flash_message :notice, I18n.t(:'peer_assessment.submission.already_submitted')
      return redirect_to peer_assessment_step_submission_path(
        short_uuid(@assessment.id),
        short_uuid(@current_step.id)
      )
    end

    @submission = PeerAssessment::SubmissionForm.new(@submission)
  end

  ### TODO: Own controller for this?
  def additional_attempt
    @user, @submission = load_user_and_submission
    Acfs.run

    @file_upload = FileUpload.new(
      purpose: :peerassessment_submission_attachment,
      size: (0..the_assessment.max_file_size * 1024 * 1024)
    )

    if @submission.additional_attempts <= 0
      add_flash_message :error, I18n.t(:'peer_assessment.submission.additional_attempt.not_allowed')
      return redirect_to action: :show
    end

    @submission = PeerAssessment::SubmissionForm.new(@submission)
  end

  def additional_attempt_update
    @user, @submission = load_user_and_submission
    Acfs.run

    if @submission.additional_attempts <= 0
      add_flash_message :error, I18n.t(:'peer_assessment.submission.additional_attempt.not_allowed')
      return redirect_to action: :show
    end

    @submission = PeerAssessment::SubmissionForm.new(@submission)
    @submission.attributes = update_params

    unless submission_ready? @submission
      add_flash_message :error, I18n.t(:'peer_assessment.submission.content_missing')
      return redirect_to action: :additional_attempt
    end

    if @submission.save(params: {additional_attempt_update: true})
      add_flash_message :success, I18n.t(:'peer_assessment.submission.success')
      redirect_to action: :show
    else
      add_flash_message :error, I18n.t(:'peer_assessment.submission.additional_attempt.update_error')
      render 'additional_attempt'
    end
  end

  def autosave
    submission = fetch_submission
    @submission = PeerAssessment::SubmissionForm.new(submission)

    Acfs.run

    if @submission.submitted
      message = I18n.t :'peer_assessment.submission.already_submitted'
      return render json: {success: false, message:}
    end

    @submission.attributes = update_params

    if @submission.save
      render json: {success: true, timestamp: Time.zone.now}
    else
      message = I18n.t :'peer_assessment.autosave.error'
      render json: {success: false, message:}
    end
  end

  def update
    @user, @submission = load_user_and_submission

    Acfs.run

    @submission = PeerAssessment::SubmissionForm.new(@submission)

    if @submission.submitted
      add_flash_message :notice, I18n.t(:'peer_assessment.submission.already_submitted')
      return redirect_to peer_assessment_step_path(
        short_uuid(@assessment.id),
        short_uuid(@participant.current_step)
      )
    end

    @submission.attributes = update_params
    @submission.submitted = true

    advance
  end

  def upload
    @user, @submission = load_user_and_submission
    Acfs.run

    if !@submission || (@submission['submitted'] && (@submission['additional_attempts'] <= 0))
      return render json: {success: false}, status: :bad_request
    end

    if @submission['attachments'].size >= @assessment['allowed_attachments']
      return render json: {success: false, error: I18n.t(:'peer_assessment.submission.upload_limit_reached')},
        status: :bad_request
    end

    if params[:upload_uri].blank?
      render json: {success: false, error: I18n.t(:'peer_assessment.submission.no_file_provided')},
        status: :bad_request
    end

    registration = @submission.rel(:files).post(
      upload_uri: params.require(:upload_uri),
      user_id: current_user.id
    )
    if registration.value.nil?
      return render json: {success: false, error: I18n.t(:'peer_assessment.submission.upload_failed')},
        status: :internal_server_error
    end

    render json: {success: true, upload: registration.value}
  end

  def remove_file
    @user, submission = load_user_and_submission

    file = submission['attachments'].find {|f| f['id'] == params[:file_id] }
    if !file ||
       (file['user_id'] != current_user.id && team_members(the_course.id, current_user.id).exclude?(file['user_id']))
      return render json: {
        success: false,
        message: I18n.t(:'peer_assessment.submission.unauthorized'),
      }
    end

    submission.rel(:file).delete(id: file['id']).value!
    render json: {success: true}
  rescue Restify::ResponseError => e
    ::Mnemosyne.attach_error(e)
    ::Sentry.capture_exception(e)
    render json: {
      success: false,
      message: I18n.t(:'peer_assessment.submission.file_delete_failed'),
    }
  end

  private

  def load_user_and_submission
    user_id = if params[:mode] == 'teacherview' && current_user.allowed?('peerassessment.submission.inspect')
                params[:examined_user_id]
              else
                current_user.id
              end

    user = account_api.rel(:user).get(id: user_id).value!
    submission = fetch_submission(owner: false, user_id: user['id'])
    [user, submission]
  end

  def update_params
    params.require(:xikolo_peer_assessment_submission).permit(
      :disallowed_sample,
      :gallery_opt_out,
      :text
    )
  end

  def advance
    Acfs.run unless the_participant.loaded?
    return unless advancement_checks

    if @participant.save(params: {update_type: 'advance'})
      redirect_to peer_assessment_path short_uuid(the_assessment.id)
      add_flash_message :success, I18n.t(:'peer_assessment.submission.success')
    else
      @participant.errors.messages[:base].each do |msg|
        add_flash_message :error, I18n.t(:"peer_assessment.advancement.errors.#{msg}")
      end
      abort_and_reset_submission
    end
  end

  def advancement_checks
    if !submission_ready? @submission
      add_flash_message :error, I18n.t(:'peer_assessment.submission.content_missing')
      redirect_to peer_assessment_step_path params[:peer_assessment_id], params[:step_id]
      false
    elsif @submission.save
      true
    else
      abort_submission
      false
    end
  end

  def abort_and_reset_submission
    @submission.submitted = false
    @submission.save params: {reset: true}

    abort_submission
  end

  def abort_submission
    add_flash_message :error, I18n.t(:'peer_assessment.submission.save_error')
    redirect_to peer_assessment_step_path params[:peer_assessment_id], params[:step_id]
  end
end
# rubocop:enable all
