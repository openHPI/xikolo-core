# frozen_string_literal: true

module Xikolo
  class API < Grape::API::Instance
    # This is the place to list supported API versions, from old to new,
    # and (optionally) their expiry dates.
    #
    # When introducing backwards-incompatible changes, a new major version
    # should be added to this array. For backwards-compatible changes,
    # please increase the minor version number of each affected version.
    #
    # Once an expiry date has passed, the corresponding version can be
    # safely removed.
    def self.supported_versions
      [
        Versioning::Version.new('4.10'),
      ]
    end

    def self.latest_version
      supported_versions.last
    end

    content_type :xml, 'application/xml'
    content_type :json, 'application/json'
    content_type :json_api, 'application/vnd.api+json'

    formatter :json, Format::PrettyJSON
    formatter :json_api, ->(str, _env) { JSON.pretty_generate JSON.parse(str) }
    parser :json_api, Grape::Parser::Json

    default_format :json

    helpers Auth::Helpers
    helpers Model::Helpers

    use Xikolo::Versioning::Middleware
    use Auth::Middleware::LegacyToken
    use Auth::Middleware::Session

    after do
      header 'Access-Control-Allow-Origin', '*'
      header 'Access-Control-Request-Method', '*'
    end

    # Convert exceptions into proper HTTP status codes
    rescue_from Error::Base, ->(e) { error! e.message, e.status }

    mount V2::Base

    get do
      content_type 'application/vnd.api+json'
      {
        data: nil,
        links: {},
      }.to_json
    end

    def self.make_docs!
      Xikolo::Docs::Generator.new('./doc/api/', V2::Base).generate!
    end
  end
end
