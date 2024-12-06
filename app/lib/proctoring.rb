# frozen_string_literal: true

module Proctoring
  class << self
    def config(key)
      Xikolo.config.proctoring[key]
    end

    def enabled?
      # Check whether proctoring is configured correctly for the platform
      Xikolo.config.proctoring.present? &&
        Xikolo.config.proctoring_smowl_endpoints.present? &&
        Xikolo.config.proctoring_smowl_options.present? &&
        entity.present? &&
        license_key.present? &&
        password.present?
    end

    def smowl_config(key)
      Xikolo.config.proctoring_smowl_endpoints[key]
    end

    def smowl_option(key)
      Xikolo.config.proctoring_smowl_options[key]
    end

    def entity
      Rails.application.secrets.smowl_entity
    end

    def license_key
      Rails.application.secrets.smowl_license_key
    end

    def password
      Rails.application.secrets.smowl_password
    end

    def store_url
      configured_url = config 'store_url'

      # If the config is a string, that's our URL and we're done
      return configured_url if configured_url.respond_to? :to_str

      # Otherwise, we assume one URL per locale, and fall back to English
      configured_url[I18n.locale.to_s] || configured_url['en']
    end
  end

  class ApiError < RuntimeError; end

  class ServiceError < RuntimeError; end
end
