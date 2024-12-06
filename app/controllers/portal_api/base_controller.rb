# frozen_string_literal: true

module PortalAPI
  def self.enabled?
    Xikolo.config.portal_api['enabled']
  end

  def self.shared_secret
    Rails.application.secrets.portal_api
  end

  def self.realm
    Xikolo.config.portal_api['realm']
  end

  class BaseController < ActionController::API
    before_action do
      raise AbstractController::ActionNotFound unless PortalAPI.enabled?
    end

    rescue_from ActionDispatch::Http::Parameters::ParseError do
      problem_details(
        'invalid_request',
        'Your request seems to contain some syntax errors. Please review it and try again.',
        status: :bad_request
      )
    end

    private

    def require_authorization_header!
      return if request.headers['HTTP_AUTHORIZATION'].present?

      response.headers['WWW-Authenticate'] = "Bearer realm=\"#{PortalAPI.realm}\""

      problem_details(
        'unauthenticated',
        'You must provide an Authorization header to access this resource.',
        status: :unauthorized
      )
    end

    def require_shared_secret!
      return if request.headers['HTTP_AUTHORIZATION'] == "Bearer #{PortalAPI.shared_secret}"

      response.headers['WWW-Authenticate'] = "Bearer realm=\"#{PortalAPI.realm}\", error=\"invalid_token\""

      problem_details(
        'invalid_token',
        'The bearer token you provided was invalid, has expired or has been revoked.',
        status: :unauthorized
      )
    end

    def allow_content_types!(allowed)
      return if allowed.include? request.headers['HTTP_ACCEPT']

      if request.headers['HTTP_ACCEPT'].blank?
        problem_details(
          'accept_header_missing',
          'You must provide the desired content type in the Accept request header.',
          status: :not_acceptable
        )
      else
        problem_details(
          'unsupported_content_type',
          'The media type provided in the "Accept" request header is not supported by this endpoint.',
          status: :not_acceptable
        )
      end
    end

    def require_request_body!
      return unless request.raw_post.empty?

      problem_details('empty_request_body', 'The request body cannot be blank.', status: :bad_request)
    end

    def problem_details(type, title, status:, **)
      render(
        content_type: 'application/problem+json',
        json: {
          type: "https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors##{type}",
          title:,
          status: Rack::Utils.status_code(status),
        },
        status:,
        **
      )
    end
  end
end
