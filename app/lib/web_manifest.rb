# frozen_string_literal: true

module WebManifest
  class << self
    def configured?
      config.is_a? Hash
    end

    def background_color
      config['bg_color']
    end

    def icons
      return [] if config['icons_dir'].nil?

      icons_in icons_dir.join(config['icons_dir'], '*.png')
    end

    def opaque_icons
      if config['icons_dir'].nil?
        []
      elsif icons_dir.join(config['icons_dir'], 'opaque').exist?
        icons_in icons_dir.join(config['icons_dir'], 'opaque', '*.png')
      else
        icons
      end
    end

    def prefer_native_apps?
      configured? && config['native_apps'].is_a?(Hash)
    end

    def linked_apps
      return [] unless prefer_native_apps?

      @linked_apps ||= config['native_apps'].each_with_index.map do |app|
        {
          platform: app[0],
          id: app[1],
        }
      end
    end

    def linked_app?(platform)
      !linked_app(platform).nil?
    end

    def linked_app(platform)
      (
        linked_apps.find {|app| app[:platform] == platform } || {}
      ).fetch :id, nil
    end

    private

    def config
      Xikolo.config.webapp
    end

    # All properly named PNG files in the configured image directory will be listed
    # as possible icons (along with their dimensions).
    # Valid names end with their dimensions, e.g.: logo-abc-128x128.png.
    def icons_in(path)
      Dir.glob(path).collect do |icon|
        {
          src: icon,
          sizes: icon.match(/([0-9]+x[0-9]+)\.png$/),
        }
      end.select do |icon|
        icon[:sizes]
      end.collect do |icon|
        {
          src: ActionController::Base.helpers.image_path(icon[:src][icons_dir.to_s.size + 1..]),
          sizes: icon[:sizes][1],
          type: 'image/png',
        }
      end
    end

    def icons_dir
      Rails.root.join('brand', Xikolo.brand, 'assets', 'images')
    end
  end
end
