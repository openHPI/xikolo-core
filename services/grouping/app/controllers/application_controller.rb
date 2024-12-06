# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from StandardError, with: :render_unknown_error
  rescue_from ActiveRecord::RecordNotFound, with: :error_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :error_record_invalid

  # This is API!
  skip_before_action :verify_authenticity_token

  around_action :register_event_listeners

  def filter(resources, by: nil)
    resources.where! by.to_sym => params[by] if params[by].present?
  end

  def register_event_listeners(&)
    Wisper.subscribe(TestGroupListener.new, TrialResultListener.new, &)
  end

  private

  def error_not_found
    error :not_found
  end

  def error_record_invalid(exception)
    error :bad_request, json: {errors: {message: exception.message}}
  end

  def error(code, opts = {})
    render opts.merge(status: code, plain: '{}')
  end

  def render_unknown_error(err)
    Rails.logger.error err.message
    Rails.logger.error "Backtrace:\n\t#{err.backtrace.join("\n\t")}"
    error :internal_server_error, json: {errors: {message: err.message}}
  end
end
