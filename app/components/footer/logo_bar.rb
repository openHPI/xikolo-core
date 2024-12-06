# frozen_string_literal: true

module Footer
  class LogoBar < ApplicationComponent
    private

    def render?
      logos.present?
    end

    def logos
      Xikolo.config.footer['logo_bar']&.map do |logo_config|
        Footer::Logo.new(
          logo_config['file_name'],
          alt: Translations.new(logo_config['alt']),
          href: logo_config['href']
        )
      end
    end
  end
end
