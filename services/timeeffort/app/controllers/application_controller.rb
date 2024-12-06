# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ::ActiveRecord::RecordNotFound do |_err|
    render status: :not_found, json: {}
  end
end
