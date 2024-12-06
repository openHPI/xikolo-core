# frozen_string_literal: true

module Dashboard
  class GamificationBadge < ApplicationComponent
    # @param badge [Gamification::Badge]
    def initialize(badge)
      @badge = badge
    end

    def call
      helpers.image_tag image_source, alt: title
    end

    private

    def title
      # TODO: Move to locale file
      if gained?
        "#{@badge.name.titleize} (#{level_title})"
      else
        @badge.name.titleize
      end
    end

    def image_source
      if gained?
        "gamification/badges/#{@badge.name.downcase}_#{@badge.level}.png"
      else
        "gamification/badges/#{@badge.name.downcase}_not_gained.png"
      end
    end

    def gained?
      @badge.persisted?
    end

    def level_title
      lookup = [
        :"gamification.badge.level.#{@badge.name.downcase}.#{@badge.level}",
        :"gamification.badge.level.default.#{@badge.level}",
        @badge.level,
      ]

      I18n.t(lookup.shift, default: lookup)
    end
  end
end
