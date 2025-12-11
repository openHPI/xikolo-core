# frozen_string_literal: true

module QuizService
class QuizDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      **fields,
      **urls,
    }.as_json(opts)
  end

  private

  def fields
    {
      id:,
      instructions:,
      time_limit_seconds:,
      unlimited_time:,
      allowed_attempts:,
      unlimited_attempts:,
      max_points:,
      current_time_limit_seconds:,
      current_unlimited_time:,
      current_allowed_attempts:,
      current_unlimited_attempts:,
      external_ref_id:,
    }
  end

  def urls
    {
      submission_statistic_url: h.submission_statistic_path(id:),
    }
  end

  def instructions
    markup = object.instructions
    if context[:raw]
      Xikolo::S3.media_refs(markup, public: true).merge(markup:)
    else
      Xikolo::S3.externalize_file_refs markup, public: true
    end
  end
end
end
