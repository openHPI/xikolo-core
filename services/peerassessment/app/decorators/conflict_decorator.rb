# frozen_string_literal: true

class ConflictDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    attrs = {
      id:,
      conflict_subject_id:,
      conflict_subject_type:,
      reason:,
      reporter:,
      legitimate: true, # @deprecated
      open: open?,
      comment:,
      peer_assessment_id:,
      accused:,
      created_at:,
    }

    if conflict_subject_type == 'Submission' && peer_assessment.is_team_assessment
      attrs[:accused_team_members] = conflict_subject.team_submissions.pluck(:user_id)
    end

    attrs.as_json(opts)
  end
end
