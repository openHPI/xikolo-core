# frozen_string_literal: true

module NotificationService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  # Skip CSRF if defined (avoid raising when the callback isn't present in test boot)
  skip_before_action :verify_authenticity_token, raise: false
end
end
