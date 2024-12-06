# frozen_string_literal: true

class WellKnownFile
  # See https://developers.google.com/digital-asset-links
  class GoogleAssetLinks
    def as_json
      [{
        relation: %w[
          delegate_permission/common.handle_all_urls
          delegate_permission/common.use_as_origin
        ],
        target: {
          namespace: 'android_app',
          package_name:,
          sha256_cert_fingerprints:,
        },
      }]
    end

    def configured?
      config.is_a?(Hash) && package_name? && sha256_cert_fingerprints?
    end

    private

    def package_name?
      !package_name.nil?
    end

    def package_name
      config['package_name']
    end

    def sha256_cert_fingerprints?
      sha256_cert_fingerprints.is_a?(Array)
    end

    def sha256_cert_fingerprints
      config['sha256_cert_fingerprints']
    end

    def config
      Xikolo.config.app_links_verification['android']
    end
  end
end
