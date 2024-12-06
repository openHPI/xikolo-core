# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :error_not_found

  def error_not_found
    error :not_found
  end

  def error(code, opts = {})
    render({plain: '{}', status: code}.merge(opts))
  end

  def index
    render json: rfc6570_routes.transform_keys {|n| "#{n}_url" }
  end
end
