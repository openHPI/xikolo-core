# frozen_string_literal: true

class PeerAssessmentDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      title:,
      instructions:,
      course_id:, # Backwards reference for index action
      max_points:,
      item_id:, # Backwards reference for most of the other actions,
      grading_hints:,
      usage_disclaimer:,
      allow_gallery_opt_out:,
      allowed_attachments:,
      max_file_size:,
      allowed_file_types:,
      attachments:,
      gallery_entries:,
      is_team_assessment:,
      user_steps_url: h.peer_assessment_user_steps_rfc6570.partial_expand(peer_assessment_id: id),
      files_url: h.peer_assessment_files_rfc6570.partial_expand(peer_assessment_id: id),
      file_url: h.peer_assessment_file_rfc6570.partial_expand(peer_assessment_id: id),
    }.as_json(opts)
  end

  def attachments
    PeerAssessmentFileDecorator.decorate_collection model.files
  end

  def instructions
    if context[:raw]
      Xikolo::S3.media_refs(object.instructions, public: true)
        .merge('markup' => object.instructions)
    else
      Xikolo::S3.externalize_file_refs(object.instructions, public: true)
    end
  end
end
