# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_default_format

  rescue_from ActionController::ParameterMissing do |e|
    render status: :bad_request, json: {error: e.message}
  end

  def set_default_format
    request.format = :json if request.accept.blank?
  end
end
