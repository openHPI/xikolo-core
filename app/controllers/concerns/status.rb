# frozen_string_literal: true

# Defines exception classes to abort controller processing to
# return a not found, unauthorized, redirect response
#
# Aborting the workflow from before_actions and other helpers
# is limited to exception raises/throwing.
#
# This concern defines a few important actions
# (`Status::NotFound`, `Status::Unauthorized`,
# `Status::Redirct`) and implements corresponding
# `rescue_from` statements to handle them.

module Status
  extend ActiveSupport::Concern

  class Base < StandardError
  end

  class Unauthorized < Base
  end

  class NotFound < Base
  end

  ##
  # Abort the request and trigger a redirect.
  #
  # Raise this exception when you want to abort control flow in a controller's
  # helper method, e.g. for loading a Restify resource that is needed for all
  # or multiple actions in that controller.
  #
  # Example:
  #
  #   def course
  #     Xikolo.api(:course).value!.rel(:course).get({id: id_from_http}).value!
  #   rescue Restify::NotFound
  #     raise Status::Redirect.new 'a reason for the log', courses_path
  #   end
  #
  # NOTE: This is a hack. In general, `redirect_to` or other Rails conventions
  # are preferred. Precondition checks can be done in before filters, where any
  # rendered response (such as a redirect) aborts further request handling.
  # Beyond that, controllers should be thin, actions can e.g. catch domain
  # exceptions from other layers / modules.
  #
  class Redirect < Base
    attr_reader :reason, :url

    def initialize(reason, url)
      super("Redirect requested: #{reason}")
      @reason = reason
      @url = url
    end
  end

  included do
    rescue_from Unauthorized do
      add_flash_message :error, I18n.t('flash.error.not_authorized')
      redirect_to root_url
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      render 'errors/csrf_error', layout: 'error', status: :unprocessable_entity
    end

    rescue_from Acfs::ResourceNotFound do
      raise NotFound
    end

    rescue_from Redirect do |err|
      Rails.logger.debug err.message
      redirect_to err.url
    end
  end
end
