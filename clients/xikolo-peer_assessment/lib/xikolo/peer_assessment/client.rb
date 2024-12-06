# frozen_string_literal: true

# Service client definition.
#
module Xikolo
  module PeerAssessment
    class Client < Acfs::Service
      identity :peerassessment

      use Acfs::Middleware::JsonDecoder
      use Acfs::Middleware::JsonEncoder

      class SystemInfo < Acfs::Resource
        service Xikolo::PeerAssessment::Client, path: 'system_info'

        attribute :running, :boolean
        attribute :build_time, :string
        attribute :build_number, :integer
        attribute :version, :string
        attribute :hostname, :string
      end
    end
  end
end
