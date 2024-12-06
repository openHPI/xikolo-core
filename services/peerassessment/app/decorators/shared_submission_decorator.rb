# frozen_string_literal: true

class SharedSubmissionDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      peer_assessment_id:,
      text:,
      additional_attempts:,
      submitted:,
      disallowed_sample:,
      gallery_opt_out:,
      attachments:,
      updated_at:,
      created_at:,
      submission_ids:,
    }.as_json(opts)
  end

  def attachments
    SubmissionFileDecorator.decorate_collection model.files
  end
end
