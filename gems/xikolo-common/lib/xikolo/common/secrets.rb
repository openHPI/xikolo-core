# frozen_string_literal: true

module Xikolo
  module Common
    module Secrets
      def self.included(base)
        # When including into a Rails::Application, we need to patch the
        # `config` object to fallback to `secrets.secret_key_base`
        # again.
        base.config.extend(Configuration)

        # Add secrets.yml discovery again
        base.config.paths.add 'config/secrets', with: 'config', glob: 'secrets.yml'
      end

      def secrets
        @secrets ||= begin
          secrets = ActiveSupport::OrderedOptions.new
          files = config.paths['config/secrets'].existent
          secrets.merge! _load_secrets(files, env: Rails.env)

          # Fallback to config.secret_key_base if secrets.secret_key_base isn't set
          secrets.secret_key_base ||= config.secret_key_base

          secrets
        end
      end

      private

      def _load_secrets(files, env:)
        require 'erb'

        files.each_with_object({}) do |path, secrets|
          data = ActiveSupport::ConfigurationFile.parse(path)

          secrets.merge!(data['shared'].deep_symbolize_keys) if data['shared']
          secrets.merge!(data[env].deep_symbolize_keys) if data[env]
        end
      end

      module Configuration
        def secret_key_base
          @secret_key_base || begin
            self.secret_key_base = begin
              if generate_local_secret?
                generate_local_secret
              else
                ENV['SECRET_KEY_BASE'] ||
                  Rails.application.credentials.secret_key_base ||
                  Rails.application.secrets.secret_key_base
              end
            end
          end
        end
      end
    end
  end
end
