# frozen_string_literal: true

class WebManifestController < ApplicationController
  before_action do
    # If the manifest is not properly configured, don't render one
    raise AbstractController::ActionNotFound unless WebManifest.configured?
  end

  def show
    manifest = {
      name: Xikolo.config.site_name,
      short_name: Xikolo.config.site_name,
      start_url: dashboard_path(tracking_campaign: 'web_app_manifest'),
      display: 'standalone',
      icons: WebManifest.icons,
      prefer_related_applications: WebManifest.prefer_native_apps?,
      related_applications: WebManifest.linked_apps,
    }

    # A background color to show behind the icon when the app is being launched
    manifest[:background_color] = WebManifest.background_color if WebManifest.background_color

    render json: manifest
  end
end
