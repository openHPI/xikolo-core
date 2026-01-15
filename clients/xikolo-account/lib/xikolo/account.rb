# frozen_string_literal: true

require 'acfs'

module Xikolo
  module Account
    require 'xikolo/account/client'

    # Now require your resources in Xikolo namespace to
    # make them available as e.g. `Xikolo::User`.^
    require 'xikolo/account/authorization'
    require 'xikolo/account/email'
    require 'xikolo/account/user'
    require 'xikolo/account/password_reset'
    require 'xikolo/account/preferences'
    require 'xikolo/account/session'
    require 'xikolo/account/statistic'
    require 'xikolo/account/token'
    require 'xikolo/account/features'
  end
end
