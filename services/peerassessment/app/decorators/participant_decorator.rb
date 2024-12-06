# frozen_string_literal: true

class ParticipantDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      user_id:,
      peer_assessment_id:,
      expertise:,
      current_step:,
      completion: current_step.try(:completion),
      grading_weight:,
      group_id:,
    }.as_json(opts)
  end
end
