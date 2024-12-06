# frozen_string_literal: true

module ProfileCompletion
  class UpdateJob < ApplicationJob
    queue_as :default

    def perform(id)
      User.find_by(id:)&.update_profile_completion!
    end
  end
end
