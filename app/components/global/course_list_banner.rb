# frozen_string_literal: true

module Global
  class CourseListBanner < ApplicationComponent
    CACHE_DURATION = 30.minutes.freeze

    def render?
      banner.present?
    end

    private

    def banner
      @banner ||= Rails.cache.fetch(
        'web/banners/current',
        expires_in: CACHE_DURATION,
        race_condition_ttl: 1.minute
      ) { Banner.current }
    end

    def link
      banner.link_url
    end

    def link_target_options
      return {} if banner.link_target.blank?

      if banner.link_target == 'blank'
        {target: '_blank', rel: 'noopener'}
      else
        {target: "_#{banner.link_target}"}
      end
    end

    def image_url
      banner.image_url
    end

    def alt_text
      banner.alt_text
    end
  end
end
