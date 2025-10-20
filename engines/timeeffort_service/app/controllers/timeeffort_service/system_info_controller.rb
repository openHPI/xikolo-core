# frozen_string_literal: true

module TimeeffortService
class SystemInfoController < ApplicationController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def show
    respond_with \
      running: true,
      hostname: Socket.gethostname
  end
end
end
