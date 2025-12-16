# frozen_string_literal: true

# Service client definition.
#
require_relative '../acfs_auth_middleware'

module Xikolo
  module Course
    class Client < Acfs::Service
      identity :course

      use Acfs::Middleware::JsonDecoder
      use Acfs::Middleware::JsonEncoder
      use AcfsAuthMiddleware

      class SystemInfo < Acfs::Resource
        service Xikolo::Course::Client, path: 'system_info'

        attribute :running, :boolean
        attribute :build_time, :string
        attribute :build_number, :integer
        attribute :version, :string
        attribute :hostname, :string
      end
    end
  end
end
