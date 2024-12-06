# frozen_string_literal: true

module Chromecast
  class << self
    def configured?
      config.is_a? Hash
    end

    def background_url
      config['background_url']
    end

    def logo_url
      config['logo_url']
    end

    def progress_color
      config['progress_color']
    end

    private

    def config
      Xikolo.config.chromecast
    end
  end
end
