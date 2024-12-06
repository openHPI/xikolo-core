# frozen_string_literal: true

class SelfAssessmentDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      peer_assessment_id:,
      deadline: deadline.try(:iso8601),
      optional:,
      position:,
      open: object.open?,
      type: "Xikolo::PeerAssessment::#{type}",
      unlock_date:,
    }.as_json(opts)
  end
end
