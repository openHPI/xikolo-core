# frozen_string_literal: true

module Video
  class Bunny
    # Raised for any failure talking to the Bunny API: network errors,
    # timeouts, and non-successful HTTP responses. The upload jobs retry on
    # this a limited number of times, which covers both transient outages
    # and permanent problems (e.g. bad credentials) without the distinction.
    class Error < StandardError; end

    NETWORK_ERRORS = [
      Net::OpenTimeout,
      Net::ReadTimeout,
      SocketError,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ETIMEDOUT,
      Errno::EHOSTUNREACH,
    ].freeze

    # Sends a request to the Bunny API and returns the parsed JSON body.
    # Raises Error on network failures or non-successful responses.
    def self.request(request)
      body =
        begin
          response = Net::HTTP.start(request.uri.host, request.uri.port, use_ssl: true) {|http| http.request(request) }

          unless response.is_a?(Net::HTTPSuccess)
            raise Error.new("Bunny #{request.method} #{request.uri}: HTTP #{response.code} #{response.body}")
          end

          response.body
        rescue *NETWORK_ERRORS => e
          raise Error.new("Bunny #{request.method} #{request.uri}: #{e.class}")
        end

      JSON.parse(body)
    end
  end
end
