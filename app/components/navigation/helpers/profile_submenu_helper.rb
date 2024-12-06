# frozen_string_literal: true

module Navigation::Helpers
  module ProfileSubmenuHelper
    def submenu_for(user, config)
      if config.blank?
        UserAccountNavigation
          .items_for(user)
          .map do |item|
            {
              text: item.text,
              active: item.active?(helpers.request),
              href: item.link,
              icon: item.icon_class,
            }
          end
      else
        Submenu.new(helpers, config).items
      end
    end

    class Submenu
      def initialize(context, config)
        @context = context
        @config = config
      end

      def items
        @config.filter_map do |component|
          if component.match(/^ref:([a-z]+)/).present?
            next item_for(Regexp.last_match(1))
          end
        end
      end

      private

      def item_for(component)
        config = Xikolo.config.layout.dig('ref', component)

        # Skip the custom reference if no proper link text is provided,
        # i.e. the text is not available in any language.
        return if config.blank?
        return if config.fetch('text').empty?

        {
          text: Translations.new(config.fetch('text')),
          active: @context.current_page?(config.fetch('href')),
          href: config.fetch('href'),
          icon: config.fetch('icon'),
        }
      rescue KeyError
        # If the configuration for a custom reference is
        # invalid or incomplete, it is ignored.
        # The link target/href, text and an icon
        # must be given.
        nil
      end
    end
  end
end
