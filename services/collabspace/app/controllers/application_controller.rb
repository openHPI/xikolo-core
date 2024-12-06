# frozen_string_literal: true

class ApplicationController < ActionController::API
  extend Responders::ControllerMethod

  rescue_from ::ActiveRecord::RecordNotFound do |_err|
    render status: :not_found, json: {}
  end
end
