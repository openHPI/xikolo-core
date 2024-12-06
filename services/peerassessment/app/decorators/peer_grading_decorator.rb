# frozen_string_literal: true

class PeerGradingDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      unlock_date:,
      peer_assessment_id:,
      deadline: deadline.try(:iso8601),
      optional:,
      position:,
      open: object.open?,
      required_reviews:,
      type: "Xikolo::PeerAssessment::#{type}",
    }.as_json(opts)
  end
end
