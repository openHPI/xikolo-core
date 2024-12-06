# frozen_string_literal: true

module Xikolo::Common::Rack
  class AlwaysContinue
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['HTTP_EXPECT'].include?('100-continue')
        [100, {}, ['']]
      else
        @app.call(env)
      end
    end
  end
end
