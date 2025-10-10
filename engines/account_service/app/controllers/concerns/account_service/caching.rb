# frozen_string_literal: true

module AccountService
module Caching # rubocop:disable Layout/IndentationWidth
  def caching(key, &)
    if perform_caching?
      Rails.cache.fetch("account/#{request.host_with_port}/#{key}", &)
    else
      yield
    end
  end

  private

  def perform_caching?
    Rails.application.config.action_controller.perform_caching
  end
end
end
