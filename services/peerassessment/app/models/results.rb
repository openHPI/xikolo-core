# frozen_string_literal: true

class Results < Step
  def on_step_enter(user_id)
    # Ensure grade object
    submission = Submission.joins(:shared_submission)
      .find_by user_id:, shared_submissions: {peer_assessment_id:}

    submission&.team_submissions&.each do |s|
      s.grade.compute_grade(recompute: true)
    end
  end

  def completion(_curr_user)
    deadline&.past? ? 1.0 : 0.0
  end
end
