# frozen_string_literal: true

module NotificationService
  class ApplicationJob < ActiveJob::Base
    queue_as 'default'
  end
end
