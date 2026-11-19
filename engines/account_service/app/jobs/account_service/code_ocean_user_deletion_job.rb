# frozen_string_literal: true

module AccountService
  class CodeOceanUserDeletionJob < ApplicationJob
    queue_as :default

    def perform(user_id)
      AccountService::CodeOceanClient.delete_user(user_id)
    rescue Faraday::ResourceNotFound
      # User not found, do nothing.
    end
  end
end
