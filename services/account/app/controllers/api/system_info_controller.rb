# frozen_string_literal: true

class API::SystemInfoController < API::BaseController
  respond_to :json

  def show
    respond_with \
      running: true,
      hostname: Socket.gethostname
  end
end
