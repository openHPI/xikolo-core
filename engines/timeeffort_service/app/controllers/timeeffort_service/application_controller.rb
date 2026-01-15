# frozen_string_literal: true

module TimeeffortService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  # Skip CSRF if defined (avoid raising when the callback isn't present in test boot)
  skip_before_action :verify_authenticity_token, raise: false

  rescue_from ::ActiveRecord::RecordNotFound do |_err|
    render status: :not_found, json: {}
  end
end
end
