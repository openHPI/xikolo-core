# frozen_string_literal: true

class AcfsAuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(request)
    request.headers['Authorization'] = "Bearer #{ENV.fetch('XIKOLO_WEB_API', nil)}"
    @app.call(request)
  end
end
