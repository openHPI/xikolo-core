# frozen_string_literal: true

module PinboardService
class AbuseReportDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id:,
      reason: '',
      reportable_id:,
      reportable_type:,
      user_id:,
      url:,
      created_at:,
      question_title:,
    }.as_json(opts)
  end
end
end
