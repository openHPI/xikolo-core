# frozen_string_literal: true

module PinboardService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  rescue_from ActiveRecord::RecordNotFound, with: :error_404
  # Skip CSRF if defined (avoid raising when the callback isn't present in test boot)
  skip_before_action :verify_authenticity_token, raise: false

  def error(code, opts = {})
    render({json: {}, status: code}.merge(opts))
  end

  def error_404
    error 404
  end

  def index
    render json: rfc6570_routes.transform_keys {|n| "#{n}_url" }
  end
end
end
