# frozen_string_literal: true

class TrialResultListener
  def trial_result_changed(trial_result)
    trial_result.test_group.compute_waiting_count trial_result.metric
    trial_result.test_group.save!
  end
end
