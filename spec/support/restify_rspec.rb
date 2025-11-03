# frozen_string_literal: true

require 'rspec/matchers'

module Restify
  module RSpec
    def respond_with(*)
      RespondWithMatcher.new(*)
    end

    def include_header(*)
      IncludeHeaderMatcher.new(*)
    end

    class RespondWithMatcher < ::RSpec::Matchers::BuiltIn::Eq
      def matches?(subject)
        @subject = subject

        if subject.respond_to? :response
          super(subject.response.status)
        else
          super(subject.status)
        end
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

        super
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

RSpec.configure {|c| c.include Restify::RSpec }
