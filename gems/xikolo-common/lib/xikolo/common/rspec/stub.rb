# frozen_string_literal: true

module Xikolo
  module Common
    module RSpec
      module Stub
        class << self
          def services
            @services ||= {}
          end

          def remember_services(config)
            services.merge! config
          end

          def enable(service)
            API.assign service, services.fetch(service)
          end

          def service(service, relations = {})
            enable service
            WebMock.stub_request(:get, API.services.fetch(service))
              .to_return json(relations)
          rescue KeyError
            raise API::ServiceNotConfigured.new(service)
          end

          def request(service, http_method, path, **request_params)
            unless Xikolo.api?(service)
              raise ArgumentError.new <<~ERR
                Service #{service} is unknown: Forgot `Stub.service` or `Stub.enable`?
              ERR
            end

            uri_matcher = if path.is_a?(Addressable::Template)
                            # URI templates will be prefixed with the service's base URL
                            Addressable::Template.new(Xikolo::Common::API.services[service] + path.pattern)
                          else
                            # Strings will be prefixed as well
                            Xikolo::Common::API.services[service] + path
                          end

            WebMock.stub_request(http_method, uri_matcher).tap do |stub|
              stub.with(request_params) unless request_params.empty?
            end
          end

          def response(body: nil, links: {}, **kwargs)
            response = {status: 200, body:, headers: {}}.merge kwargs

            unless links.empty?
              links = links.map {|name, value| "<#{value}>;rel=#{name}" }
                .unshift(response[:headers]['Link'])
                .compact

              response[:headers]['Link'] = links.join ', '
            end

            response
          end

          def json(json, **kwargs)
            body = JSON.dump(json)
            headers = kwargs.delete(:headers) || {}

            response(
              body:,
              headers: {
                'Content-Type' => 'application/json;charset=utf-8',
                'Content-Length' => body.length,
              }.merge(headers),
              **kwargs
            )
          end
        end
      end
    end
  end
end
