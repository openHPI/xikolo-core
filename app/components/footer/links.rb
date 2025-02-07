# frozen_string_literal: true

module Footer
  class Links < ApplicationComponent
    private

    def link_columns
      Rails.cache.fetch(
        "footer/links/#{I18n.locale}",
        expires_in: 30.minutes
      ) do
        Xikolo.config.footer&.dig('columns')&.map do |links_config|
          LinkColumn.new(links_config)
        end || []
      end
    end

    class LinkColumn
      def initialize(config)
        @config = config
      end

      def css_classes
        headline? ? '' : 'mt10'
      end

      def headline?
        headline.present?
      end

      def headline
        @headline ||= Translations.new(@config['headline'])
      end

      def links
        @config['links'].filter_map do |link_config|
          resolve(link_config)
        end
      end

      private

      def resolve(component)
        if component.is_a?(String) && component.start_with?('ref:')
          return resolve_reference(component)
        end

        link_item_for(component)
      end

      def resolve_reference(component)
        config = Xikolo.config.layout.dig('ref', component.remove('ref:'))

        link_item_for(config)
      end

      def link_item_for(config)
        Global::LinkItem.new(
          href: Translations.new(config.fetch('href')).to_s,
          text: Translations.new(config.fetch('text')).to_s,
          title: Translations.new(config['title']).to_s,
          target: config['target']
        )
      rescue KeyError
        # If the configuration for a link item is
        # invalid or incomplete, it is ignored
        nil
      end
    end
  end
end
