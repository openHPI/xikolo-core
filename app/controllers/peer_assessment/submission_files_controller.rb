# frozen_string_literal: true

class PeerAssessment::SubmissionFilesController < Abstract::FrontendController
  def gallery
    # external entry point to access submission files from galleries
    pa_id = UUID4(params[:peer_assessment_id]).to_s
    submission_id = UUID4(params[:submission_id]).to_s
    file_id = UUID4(params[:id]).to_s

    api_root = Xikolo.api(:peerassessment).value!
    pa = api_root.rel(:peer_assessment).get(id: pa_id).value!
    raise Status::NotFound unless pa['gallery_entries'].include? submission_id

    submission = api_root.rel(:shared_submission).get(id: submission_id).value!
    file = submission['attachments'].find {|f| f['id'] == file_id }
    raise Status::NotFound unless file

    redirect_to file['download_url']
  rescue Restify::NotFound
    raise Status::NotFound
  end
end
