# frozen_string_literal: true

module Navigation
  class LogoPreview < ViewComponent::Preview
    def default
      render Navigation::Logo.new
    end

    def with_custom_config
      config = {href: '/', alt: {en: 'Brand logo', de: 'Brand-Logo'}}

      render Navigation::Logo.new(href: config['href'], alt: config['alt'])
    end
  end
end
