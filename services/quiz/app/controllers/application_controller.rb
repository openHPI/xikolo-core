# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :error_404

  def error(code, opts = {})
    render({plain: '{}', status: code}.merge(opts))
  end

  def error_404
    error 404
  end

  def index
    render json: rfc6570_routes.transform_keys {|n| "#{n}_url" }
  end
end
