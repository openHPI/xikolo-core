# frozen_string_literal: true

require 'acfs'

module Xikolo::Account
  # Service definition needs to subclass `Acfs::Service`.
  # This allows you to use the Acfs Service DSL to describe
  # your service e.g. used middlewares.
  #
  class Client < Acfs::Service
    # First define an identity for your service.
    # This names will be used to lookup service settings
    # like service base URI.
    #
    identity :account

    # Define used middleware e.g. for JSON decoding.
    use Acfs::Middleware::JsonDecoder
    use Acfs::Middleware::JsonEncoder

    class SystemInfo < Acfs::Resource
      service Xikolo::Account::Client, path: 'system_info'

      attribute :running, :boolean
      attribute :build_time, :string
      attribute :build_number, :integer
      attribute :version, :string
      attribute :hostname, :string
    end
  end
end
