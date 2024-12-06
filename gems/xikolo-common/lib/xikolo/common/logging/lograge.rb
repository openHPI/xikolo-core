# frozen_string_literal: true

module Xikolo::Common::Logging
  module Lograge
    class << self
      def current_request
        ::Thread.current[:request_store].try(:[], :current_controller).try(:request)
      end
    end

    module RequestLogSubscriberPatch
      def custom_options(_event)
        data = {}

        if (request = ::Xikolo::Common::Logging::Lograge.current_request)
          data[:url]        = request.url
          data[:query]      = request.query_string if request.method == 'GET'
          data[:full_path]  = request.path
          data[:full_path] += "?#{data[:query]}" if data[:query].present?
          data[:params]     = request.filtered_parameters.except(*%w[controller action format])
          data[:request_id] = request.uuid
        end

        data[:target] = "#{data[:controller]}##{data[:action]}"
        data
      end
    end

    class Formatter
      FIELDS = %i[request_id method full_path status target duration db view notice].freeze

      def call(payload)
        values = FIELDS.map {|n| format payload[n] }

        ::Kernel.format '[%.8s] %s %s %s %s %s %s %s %s', *values # rubocop:disable Style/FormatStringToken
      end

      def format(value)
        value.to_s.presence || '-'
      end
    end
  end

  ::Lograge::RequestLogSubscriber.prepend ::Xikolo::Common::Logging::Lograge::RequestLogSubscriberPatch
end
