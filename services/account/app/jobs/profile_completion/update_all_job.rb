# frozen_string_literal: true

module ProfileCompletion
  class UpdateAllJob < ApplicationJob
    queue_as :default

    def perform
      User
        .pluck(:id)
        .each {|user_id| ProfileCompletion::UpdateJob.perform_later user_id }
    end
  end
end
