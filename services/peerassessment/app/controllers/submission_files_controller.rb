# frozen_string_literal: true

class SubmissionFilesController < ApplicationController
  responders Responders::DecorateResponder

  respond_to :json

  def create
    submission = Submission.find params[:submission_id]
    shared = submission.shared_submission

    if shared.submitted && (shared.additional_attempts == 0)
      return render json: {}, status: :forbidden
    end

    current_attachments_count = shared.file_ids.count
    if current_attachments_count >= shared.peer_assessment.allowed_attachments
      return render json: {}, status: :unprocessable_content
    end

    file = shared.files.build id: SecureRandom.uuid, user_id: params.require(:user_id)
    upload = Xikolo::S3::UploadByUri.new \
      uri: params.require(:upload_uri),
      purpose: :peerassessment_submission_attachment
    return render json: {}, status: :unprocessable_content unless upload.valid?

    pid = UUID4(submission.peer_assessment.id).to_s(format: :base62)
    sid = UUID4(shared.id).to_s(format: :base62)
    fid = UUID4(file.id).to_s(format: :base62)
    file.name = "PA-Submission-#{sid}-#{fid}#{upload.extname}"
    file.size = upload.upload.size
    file.mime_type = upload.content_type
    result = upload.save bucket: :peerassessment,
      key: "assessments/#{pid}/submissions/#{sid}/attachments/#{fid}#{upload.extname}",
      content_disposition: "attachment; filename=\"#{file.name}\"",
      content_type: upload.content_type,
      acl: 'private'
    return render json: {}, status: :unprocessable_content if result.is_a?(Symbol)

    file.storage_uri = result.storage_uri
    file.save
    respond_with file, location: nil
  end

  def destroy
    submission = Submission.find params[:submission_id]
    shared = submission.shared_submission
    if (file = shared.files.find_by(id: params[:id]))
      if shared.submitted && (shared.additional_attempts == 0)
        render json: {}, status: :forbidden
      else
        Xikolo::S3.object(file.storage_uri).delete
        file.destroy
        respond_with file, location: nil
      end
    else
      render json: {}, status: :not_found
    end
  end
end
