# frozen_string_literal: true

require 'acfs'

module Xikolo
  module Submission
    class Client < Acfs::Service
      # The quiz service now offers all of our capabilities (as it can talk to
      # our database), so just talk to that.
      identity :quiz

      use Acfs::Middleware::JsonDecoder
      use Acfs::Middleware::JsonEncoder

      class SystemInfo < Acfs::Resource
        service Xikolo::Submission::Client, path: 'system_info'

        attribute :running, :boolean
        attribute :build_time, :string
        attribute :build_number, :integer
        attribute :version, :string
        attribute :hostname, :string
      end
    end
  end
end
