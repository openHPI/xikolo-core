# frozen_string_literal: true

class RootController < ApplicationController
  respond_to :json

  def index
    respond_with routes
  end

  private

  def routes
    rfc6570_routes.transform_keys {|n| "#{n}_url" }
  end
end
