# frozen_string_literal: true

module TimeeffortService
class ApplicationController < ActionController::Base # rubocop:disable Layout/IndentationWidth
  rescue_from ::ActiveRecord::RecordNotFound do |_err|
    render status: :not_found, json: {}
  end
end
end
