# frozen_string_literal: true

module CourseService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  include Vary

  # Skip CSRF if defined (avoid raising when the callback isn't present in test boot)
  skip_before_action :verify_authenticity_token, raise: false

  rescue_from ActiveRecord::RecordNotFound, with: :error_not_found
  rescue_from ActionController::ParameterMissing, with: :error_param_missing

  def api_version
    1
  end

  def error_not_found
    error :not_found
  end

  def error_param_missing(exception)
    error :unprocessable_content, json: {errors: {exception.param => 'required'}}
  end

  def rescue_from_api_error(err)
    render json: err, status: err.status
  end

  def error(code, opts = {})
    render opts.merge(status: code, plain: '{}')
  end

  def error!(...)
    raise APIError.new(...)
  end

  class APIError < StandardError
    attr_reader :status, :errors, :extra

    def initialize(errors:, status: :unprocessable_content, **extra)
      @errors = errors
      @status = status
      @extra  = extra

      super('API error')
    end

    def as_json(*)
      @extra.merge(errors:).as_json(*)
    end
  end

  rescue_from APIError, with: :rescue_from_api_error
end
end
