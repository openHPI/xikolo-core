# frozen_string_literal: true

module PostHelper
  REPORTING_THRESHOLD = 3

  def report_threshold_reached?
    abuse_reports.count >= REPORTING_THRESHOLD
  end

  def reset_reviewed
    if reviewed? && text_changed?
      update! workflow_state: :new
    end
  end
end
