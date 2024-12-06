# frozen_string_literal: true

module Footer
  class Newsletter < ApplicationComponent
    private

    def render?
      config.present?
    end

    def headline
      Translations.new config&.dig('headline')
    end

    def description
      Translations.new config&.dig('description')
    end

    def link_href
      Translations.new(config.dig('link', 'href')).to_s
    end

    def link_text
      Translations.new(config.dig('link', 'text'))
    end

    def config
      Xikolo.config.footer&.dig('newsletter')
    end
  end
end
