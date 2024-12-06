# frozen_string_literal: true

require 'xikolo/common'
require 'restify'

module Xikolo
  module Common
    module RSpec
      require 'xikolo/common/rspec/factory_girl' # @deprecated
      require 'xikolo/common/rspec/factory_bot'
      require 'xikolo/common/rspec/matchers'
      require 'xikolo/common/rspec/stub'

      def respond_with(*)
        RespondWithMatcher.new(*)
      end

      def include_header(*)
        IncludeHeaderMatcher.new(*)
      end

      def session_request_headers(session_id)
        if session_id
          {'Authorization' => "Xikolo-Session session_id=#{session_id}"}
        else
          {}
        end
      end

      def setup_session(user_id, permissions: [], features: {}, user: {}, context_id: 'root')
        if user_id.nil?
          Stub.request(
            :account, :get,
            "/sessions/anonymous?context=#{context_id}&embed=user,permissions,features"
          ).to_return Stub.json({
            id: nil,
            user_id: nil,
            masqueraded: false,
            features:,
            permissions:,
          })
          nil
        else
          session_id = generate_session_id
          Stub.request(
            :account, :get,
            "/sessions/#{session_id}?context=#{context_id}&embed=user,permissions,features"
          ).to_return Stub.json({
            id: session_id,
            user_id:,
            user: user.merge(id: user_id, anonymous: false),
            masqueraded: false,
            features:,
            permissions:,
          })
          session_id
        end
      end

      def json(resource)
        resource = resource.decorate.as_json if resource.respond_to? :decorate

        case resource
          when Array
            resource.map {|r| json(r) }
          when Hash
            resource.stringify_keys
        end.as_json
      end

      private

      def generate_session_id
        if defined?(FactoryGirl)
          FactoryGirl.generate :session_id
        elsif defined?(FactoryBot)
          FactoryBot.generate :session_id
        else
          SecureRandom.uuid
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Xikolo::Common::RSpec

  # Breaks any assumtption to lexical namespacing for constants in specs
  # but makes `Stub` available in all test blocks.
  Stub = Xikolo::Common::RSpec::Stub # rubocop:disable Lint/ConstantDefinitionInBlock

  config.before(:each) do
    # Remove all defined services, but let Stub remember the locations.
    # Stub.service will re-add the service entries.
    # This ensures all services without stubs are disabled.
    # Optional features/requests are skipped and the tests needs less stubs.
    Stub.remember_services Xikolo::Common::API.services
    Xikolo::Common::API.services.clear
  end
end
