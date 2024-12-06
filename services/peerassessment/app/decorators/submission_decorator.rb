# frozen_string_literal: true

class SubmissionDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    attrs = {
      id:,
      peer_assessment_id:,
      text:,
      user_id:,
      additional_attempts:,
      submitted:,
      disallowed_sample:,
      gallery_opt_out:,
      attachments:,
      grade: grade.try(:id),
      updated_at:,
      created_at:,
      shared_submission_id:,
      team_name:,
      files_url: h.submission_files_rfc6570.partial_expand(submission_id: id),
      file_url: h.submission_file_rfc6570.partial_expand(submission_id: id),
    }

    if context[:include_votes]
      attrs.merge!(
        average_votes:,
        votes:,
        nominations:
      )
    end

    attrs.as_json(opts)
  end

  private

  def team_name
    context[:team_names][user_id] unless context[:team_names].nil?
  end

  def attachments
    SubmissionFileDecorator.decorate_collection shared_submission.files
  end
end
