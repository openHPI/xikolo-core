# frozen_string_literal: true

class PingController < ActionController::Base # rubocop:disable Rails/ApplicationController
  ##
  # We inherit from ActionController::Base as we don't need any
  # ApplicationController handling. This controller is used for uptime checks.

  def index
    render json: {
      message: 'Pong',
      timenow_in_time_zone____: DateTime.now.in_time_zone.to_i,
      timenow_without_timezone: DateTime.now.to_i,
    }
  end
end
