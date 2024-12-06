# frozen_string_literal: true

module Footer
  class About < ApplicationComponent
    private

    def css_classes
      headline.blank? ? 'mt10' : ''
    end

    def render?
      headline.present? || description.present?
    end

    def headline
      @headline ||= Translations.new(config&.dig('headline'))
    end

    def description
      @description ||= Translations.new(config&.dig('description'))
    end

    def logo
      return unless config&.dig('logo')

      image_tag(image_path(config&.dig('logo')), alt: '', height: '50', width: '168', class: 'footer__logo')
    end

    def config
      Xikolo.config.footer&.dig('about')
    end
  end
end
