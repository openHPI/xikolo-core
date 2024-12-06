# frozen_string_literal: true

module Xikolo::Common::Tracking
  require 'addressable/uri'
  require 'digest'

  class ExternalLink
    # used to track external links via redirect
    # /go/link?url=https://some.external.link/ewfewfewf&checksum=123&tracking...

    def initialize(url, domain = '', params = {})
      @url = url
      @domain = domain
      @params = params
    end

    def to_s
      if @domain.is_a? String
        "https://#{@domain}/go/link?#{query}"
      else
        @domain.join("go/link?#{query}").to_s
      end
    end

    def valid?(other_checksum)
      checksum == other_checksum
    end

    def checksum
      @checksum ||= Digest::SHA256.hexdigest("xikolo#{@url}")[2..8]
    end

    private

    def query
      # Convert to array to preserve the order from the hash
      params = @params.to_a
      params.unshift ['checksum', checksum]
      params.unshift ['url', @url]

      uri = Addressable::URI.new
      uri.query_values = params
      uri.query
    end
  end
end
