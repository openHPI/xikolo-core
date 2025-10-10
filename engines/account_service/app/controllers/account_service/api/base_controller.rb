# frozen_string_literal: true

module AccountService
class API::BaseController < ActionController::Base # rubocop:disable Layout/IndentationWidth,Rails/ApplicationController
  include Vary

  # This is API!
  skip_before_action :verify_authenticity_token

  rescue_from ActiveRecord::RecordNotFound, with: :error_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :error_invalid

  def error_not_found
    error :not_found
  end

  def error_invalid
    error :unprocessable_content
  end

  def error(code, opts = {})
    render opts.merge(status: code, plain: '{}')
  end
end
end
