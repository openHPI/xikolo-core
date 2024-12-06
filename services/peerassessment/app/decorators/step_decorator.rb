# frozen_string_literal: true

class StepDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    if object.instance_of? Step
      return base_decoration.as_json(opts)
    end

    begin
      "#{object.class}Decorator".constantize.send(:decorate, object, context:).as_json(opts)
    rescue Error # Fallback to base class decorator
      base_decoration.as_json(opts)
    end
  end

  def base_decoration
    {
      id:,
      peer_assessment_id:,
      deadline: deadline.try(:iso8601),
      optional:,
      position:,
      open: object.open?,
      type: "Xikolo::PeerAssessment::#{type}",
      unlock_date:,
    }
  end
end
