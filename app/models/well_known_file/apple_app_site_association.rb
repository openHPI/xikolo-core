# frozen_string_literal: true

class WellKnownFile
  # See https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html
  class AppleAppSiteAssociation
    def as_json
      {
        applinks: {
          apps: [],
          details: [
            {
              appID: "#{app_id_prefix}.#{bundle_id}",
              paths: [
                '/',
                auth_path(provider: 'app'),
                "#{auth_path(provider: 'app')}*",
                dashboard_path,
                courses_path,
                "#{courses_path}/*",
                "#{channels_path}/*",
              ],
            },
          ],
        },
      }
    end

    include Rails.application.routes.url_helpers

    def configured?
      config.is_a?(Hash) && app_id_prefix? && bundle_id?
    end

    private

    def app_id_prefix?
      !app_id_prefix.nil?
    end

    def app_id_prefix
      config['app_id_prefix']
    end

    def bundle_id?
      !bundle_id.nil?
    end

    def bundle_id
      config['bundle_id']
    end

    def config
      Xikolo.config.app_links_verification['ios']
    end
  end
end
