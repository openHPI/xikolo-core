# frozen_string_literal: true

module Navigation
  class Logo < ApplicationComponent
    def initialize(basename: nil, href: nil, alt: nil)
      @basename = basename
      @href = href
      @alt = alt
    end

    private

    def href
      @href.presence || root_path
    end

    def alt
      Translations.new(@alt).presence || 'Brand logo'
    end

    def image
      image_path("#{logo_basename}.png")
    end

    def image_2x
      image_path("#{logo_basename}.2x.png")
    end

    def logo_basename
      # Locales may override the logo filename. If a locale does not provide
      # one, we fall back to the absolute default and disable fallbacks to
      # English where this isn't the platform's default locale.
      @logo_basename ||= @basename.presence || I18n.t(:'header.logo', default: 'logo', fallback: false)
    end
  end
end
