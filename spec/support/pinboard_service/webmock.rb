# frozen_string_literal: true

require 'webmock'
require 'webmock/rack_response'

# https://github.com/bblimke/webmock/issues/985
module WebmockSessionPatch
  def build_rack_env(request)
    super.tap do |env|
      env.delete('rack.session')
      env.delete('rack.session.options')
    end
  end

  WebMock::RackResponse.prepend(WebmockSessionPatch)
end
