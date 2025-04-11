# frozen_string_literal: true

class SystemInfoController < ApplicationController
  def show
    render json: {
      running: true,
      hostname: Socket.gethostname,
    }
  end
end
