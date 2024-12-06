# frozen_string_literal: true

class GradeDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      overall_grade: compute_grade,
      base_points:,
      submission_id:,
      bonus_points: bonus_points || [],
      delta:,
      absolute:,
      regradable: regradable?,
    }.as_json(opts)
  end
end
