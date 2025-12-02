# frozen_string_literal: true

# Error handler for custom pretty HTTP 4xx/5xx pages.
# Called per Rails convention via config.exceptions_app.
class ErrorsController < ApplicationController
  skip_before_action :verify_authenticity_token

  ##
  # Which error template do we want to show for which status code?
  #
  STATUS_TEMPLATES = {
    404 => :not_found,
  }.freeze

  ##
  # Log an exception and show its pretty error page.
  #
  def show
    if STATUS_TEMPLATES.key?(status_code)
      pretty_error_page STATUS_TEMPLATES[status_code]
    else
      fallback
    end
  end

  private

  ##
  # Show a pretty error page, but use the status code determined by Rails.
  #
  def pretty_error_page(template)
    respond_to do |format|
      format.html { render template: "errors/#{template}", layout: 'layouts/error', status: status_code }
      format.json do
        render json: {
          title: t(:"errors.#{template}.headline"),
          detail: t(:"errors.#{template}.message"),
          status: status_code,
          error_code: Sentry.last_event_id,
        }.compact, status: status_code, content_type: 'application/problem+json'
      end
    end
  rescue ActionController::UnknownFormat
    render \
      status: status_code,
      template: "errors/#{template}",
      handlers: %i[erb],
      formats: %i[text],
      layout: false,
      content_type: 'text/plain'
  end

  ##
  # Show a generic page for exceptions that we don't have specific pages for.
  #
  def fallback
    pretty_error_page(:server)
  end

  def status_code
    @status_code ||= request.path_info[1..].to_i
  end
end
