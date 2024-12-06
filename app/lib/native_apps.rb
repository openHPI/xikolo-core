# frozen_string_literal: true

module NativeApps
  class << self
    def enabled
      [].tap do |enabled_apps|
        enabled_apps << ios_app if ios_app?
        enabled_apps << android_app if android_app?
      end
    end

    private

    def ios_app?
      IosApp.configured?
    end

    def ios_app
      NativeAppBadge.new(
        IosApp.app_store_url,
        'native_apps/apple_app_store_badge.svg',
        I18n.t(:'footer.native_apps.apple_store_alt')
      )
    end

    def android_app?
      WebManifest.linked_app? 'play'
    end

    def android_app
      NativeAppBadge.new(
        "https://play.google.com/store/apps/details?id=#{WebManifest.linked_app 'play'}",
        'native_apps/google_play_store_badge.svg',
        I18n.t(:'footer.native_apps.google_play_alt')
      )
    end
  end

  class NativeAppBadge
    def initialize(url, image_path, alt_text = nil)
      @url = url
      @image_path = image_path
      @alt_text = alt_text
    end

    attr_reader :url, :image_path, :alt_text
  end
end
