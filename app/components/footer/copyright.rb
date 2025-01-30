# frozen_string_literal: true

module Footer
  class Copyright < ApplicationComponent
    private

    def copyright
      "&copy; #{start_year} - #{Time.current.year}"
    end

    def start_year
      config&.dig('start_year') || '2012'
    end

    def owner
      return unless config&.dig('owner')

      resolve config['owner']
    end

    def legal_links
      config&.dig('legal')&.filter_map {|component| resolve(component) } || []
    end

    def powered_by_label
      Translations.new config&.dig('powered_by', 'label')
    end

    def powered_by_links
      config&.dig('powered_by', 'links')&.filter_map do |component|
        resolve component
      end || []
    end

    def resolve(component)
      if component.is_a?(String) && component.start_with?('ref:')
        return resolve_reference(component)
      end

      link_item_for component
    end

    def resolve_reference(component)
      config = Xikolo.config.layout.dig('ref', component.remove('ref:'))

      link_item_for config
    end

    def link_item_for(config)
      Global::LinkItem.new(
        href: Translations.new(config.fetch('href')).to_s,
        text: Translations.new(config.fetch('text')),
        title: Translations.new(config['title']),
        target: '_blank'
      )
    rescue KeyError
      # If the configuration for a link item is
      # invalid or incomplete, it is ignored
      nil
    end

    def config
      Xikolo.config.footer&.dig('copyright')
    end

    def build_commit_sha
      ENV.fetch('BUILD_COMMIT_SHA', nil)
    end

    def build_commit_short_sha
      ENV.fetch('BUILD_COMMIT_SHORT_SHA', nil)
    end

    def release_number
      ENV.fetch('RELEASE_NUMBER', nil)
    end

    def release_tag
      if release_number.present? || build_commit_short_sha.present? || build_commit_sha.present?
        content_tag(
          :span,
          release_number.presence || build_commit_short_sha.presence || build_commit_sha,
          class: 'footer__release',
          title: build_commit_sha
        )
      end
    end
  end
end
