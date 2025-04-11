# frozen_string_literal: true

class RefreshSitemapJob < ApplicationJob
  queue_as :default
  queue_with_priority :reporting

  def perform
    # Do nothing since the job has been deprecated but allow
    # pending/scheduled/queued job to run to completion.
  end
end
