# frozen_string_literal: true

module Xikolo
  module Common
    module RSpec
      class RespondWithMatcher < ::RSpec::Matchers::BuiltIn::Eq
        def matches?(subject)
          @subject = subject
          super(subject.response.status)
        end

        def failure_message
          format 'expected %{subject} to respond with %{expected} but was %{actual}',
            subject: @subject.inspect,
            expected: status_text(@expected),
            actual: status_text(@actual)
        end

        def description
          "respond with #{status_text(@expected)}"
        end

        private

        def status_text(status)
          status.to_s.tr('_', ' ').upcase
        end
      end

      class IncludeHeaderMatcher < ::RSpec::Matchers::BuiltIn::Include
        def initialize(headers)
          @headers = headers

          headers = headers.each_pair.with_object({}) do |pair, hash|
            hash[pair[0].upcase.gsub(/[^A-Z]/, '_')] = pair[1]
          end

          super(headers) # rubocop:disable Style/SuperArguments
        end

        def matches?(subject)
          super(subject.response.headers)
        end

        def description
          "include #{@headers.size > 1 ? 'headers' : 'header'} #{formatted_headers.join(', ')}"
        end

        def formatted_headers
          @headers.map {|name, value| "#{name}: #{value}".inspect }
        end
      end
    end
  end
end
