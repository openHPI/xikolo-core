# frozen_string_literal: true

module Footer
  class SocialMedia < ApplicationComponent
    private

    def render?
      config.present?
    end

    def headline
      Translations.new(config&.dig('headline'))
    end

    def media_links
      config&.dig('links')&.filter_map do |link|
        media_link = MediaLink.new(link)

        # Ensure that a type for the link is configured, skip if not
        next if media_link.type.empty?

        media_link
      end || []
    end

    def config
      Xikolo.config.footer&.dig('social_media')
    end

    class MediaLink
      def initialize(config)
        @config = config
      end

      def href
        Translations.new(@config['href']).to_s
      end

      def text
        Translations.new(@config['text'])
      end

      def type
        @config['type']
      end
    end
  end
end
