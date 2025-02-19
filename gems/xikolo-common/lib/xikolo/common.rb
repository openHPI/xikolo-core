# frozen_string_literal: true

require 'yaml'

module Xikolo
  module Common
    require 'xikolo/common/api'
    require 'xikolo/common/metrics'
    require 'xikolo/common/secrets'
    require 'xikolo/common/railtie' if defined? Rails
    require 'xikolo/common/restify'

    module Auth
      require 'xikolo/common/auth/current_user'
      require 'xikolo/common/auth/middleware'
    end

    module Rack
      require 'xikolo/common/rack/always_continue'
    end

    module Tracking
      require 'xikolo/common/tracking/external_link'
    end
  end
end
