# frozen_string_literal: true

module PinboardService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  rescue_from ActiveRecord::RecordNotFound, with: :error_404

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
