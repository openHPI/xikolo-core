# frozen_string_literal: true

module Xikolo
  module Versioning
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        env['XIKOLO_API_VERSION'] = version = determine_version(env)

        status, headers, body = @app.call(env).to_a

        [status, response_headers(headers, version), body]
      rescue VersionMismatch => e
        [406, {}, [e.message]]
      end

      private

      def determine_version(env)
        requested_version = extract_version_from_accept(env['HTTP_ACCEPT'])

        return Xikolo::API.latest_version unless requested_version

        matching_version = Xikolo::API.supported_versions
          .reject(&:expired?)
          .find do |version|
          version.compatible? requested_version
        end

        raise VersionMismatch.new('Unsupported API version requested') unless matching_version

        matching_version
      end

      def extract_version_from_accept(accept_header)
        matches = /; ?xikolo-version=(.+)$/.match accept_header.to_s

        return unless matches

        Version.new matches[1]
      end

      def response_headers(old_headers, version)
        return old_headers unless old_headers['Content-Type'] == 'application/vnd.api+json'

        old_headers.merge(
          'Content-Type' => "application/vnd.api+json; xikolo-version=#{version}"
        ).tap {|headers|
          if version.expires?
            headers['Sunset'] = version.expiry_date.httpdate
            headers['X-Api-Version-Expiration-Date'] = version.expiry_date.httpdate
          end
        }
      end

      class VersionMismatch < StandardError; end
    end
  end
end
