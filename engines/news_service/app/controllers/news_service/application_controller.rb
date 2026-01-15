# frozen_string_literal: true

module NewsService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  # Skip CSRF if defined (avoid raising when the callback isn't present in test boot)
  skip_before_action :verify_authenticity_token, raise: false

  before_action :set_default_format

  rescue_from ActionController::ParameterMissing do |e|
    render status: :bad_request, json: {error: e.message}
  end

  def set_default_format
    request.format = :json if request.accept.blank?
  end
end
end
