# frozen_string_literal: true

module Authenticate
  extend ActiveSupport::Concern

  included do
    around_action :authenticate
  end

  private

  def authenticate(&app)
    request.env['xikolo_context'] = auth_context || :root

    Xikolo::Common::Auth::Middleware.new(app).call(request.env)
  end

  def auth_context
    nil
  end

  def current_user
    @current_user ||= request.env['current_user'].value!
  rescue Restify::NotFound
    raise API::RootController::NotAuthorized
  end

  def authenticate!
    raise NotAuthorized.new if current_user.anonymous?
  end

  def authorize!(permission)
    raise NotAuthorized.new unless current_user.allowed?(permission)
  end
end
