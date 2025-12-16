# frozen_string_literal: true

require_relative '../acfs_auth_middleware'

module Xikolo::Pinboard
  # Service definition needs to subclass `Acfs::Service`.
  # This allows you to use the Acfs Service DSL to describe
  # your service e.g. used middlewares.
  #
  class Client < Acfs::Service
    # First define an identity for your service.
    # This names will be used to lookup service settings
    # like service base URI.
    #
    identity :pinboard

    # Define used middleware e.g. for JSON decoding.
    use Acfs::Middleware::JsonDecoder
    use Acfs::Middleware::JsonEncoder
    use AcfsAuthMiddleware

    class SystemInfo < Acfs::Resource
      service Xikolo::Pinboard::Client, path: 'system_info'

      attribute :running, :boolean
      attribute :build_time, :string
      attribute :build_number, :integer
      attribute :version, :string
      attribute :hostname, :string
    end

    # Require defined resources here
    require 'xikolo/pinboard/answer'
    require 'xikolo/pinboard/comment'
    require 'xikolo/pinboard/question'
    require 'xikolo/pinboard/tag'
    require 'xikolo/pinboard/implicit_tag'
    require 'xikolo/pinboard/explicit_tag'
    require 'xikolo/pinboard/vote'
    require 'xikolo/pinboard/subscription'
    require 'xikolo/pinboard/statistic'
    require 'xikolo/pinboard/abuse_report'
  end

  # Require "concerns" for your resources. Concerns can be used
  # to share code between your Acfs resources and your ActiveRecord
  # database models e.g. validations.
  #
  module Concerns
  end
end
