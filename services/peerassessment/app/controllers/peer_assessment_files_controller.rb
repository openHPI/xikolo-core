# frozen_string_literal: true

class PeerAssessmentFilesController < ApplicationController
  responders Responders::DecorateResponder

  respond_to :json

  def create
    assessment = PeerAssessment.find params[:peer_assessment_id]
    file = PeerAssessmentFile.new id: SecureRandom.uuid, peer_assessment: assessment
    file.user_id = params.require(:user_id)
    upload = Xikolo::S3::UploadByUri.new \
      uri: params.require(:upload_uri),
      purpose: :peerassessment_assessment_attachment
    return render json: {}, status: :unprocessable_content unless upload.valid?

    pid = UUID4(assessment.id).to_s(format: :base62)
    fid = UUID4(file.id).to_s(format: :base62)
    file.name = upload.sanitized_name
    file.size = upload.upload.size
    file.mime_type = upload.content_type
    result = upload.save bucket: :peerassessment,
      key: "assessments/#{pid}/attachments/#{fid}_#{file.name}",
      content_disposition: "attachment; filename=\"#{file.name}\"",
      content_type: upload.content_type,
      acl: 'public-read'
    return render json: {}, status: :unprocessable_content if result.is_a?(Symbol)

    file.storage_uri = result.storage_uri
    file.save
    respond_with file, location: nil
  end

  def destroy
    assessment = PeerAssessment.find params[:peer_assessment_id]
    if (file = assessment.files.find_by(id: params[:id]))
      Xikolo::S3.object(file.storage_uri).delete
      file.destroy
      respond_with file, location: nil
    else
      render json: {}, status: :not_found
    end
  end
end
