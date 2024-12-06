# frozen_string_literal: true

require 'telegraf'

module Xikolo::Common
  module Metrics
    def metrics
      @metrics ||= ::Telegraf::Agent.new('udp://localhost:8094')
    end
  end

  ::Xikolo.extend Metrics
end
