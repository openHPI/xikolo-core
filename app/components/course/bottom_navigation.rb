# frozen_string_literal: true

module Course
  class BottomNavigation < ApplicationComponent
    # Each link contains :url, :title, :icon, and optionally :section, or is nil when absent.
    def initialize(previous_link: nil, next_link: nil)
      @previous_link = previous_link
      @next_link = next_link
    end

    def render?
      @previous_link.present? || @next_link.present?
    end

    private

    def items
      [
        item_data(@previous_link, 'prev'),
        item_data(@next_link, 'next'),
      ].compact
    end

    def item_data(link, type)
      return if link.nil?

      {
        url: link.fetch(:url),
        title: link.fetch(:title),
        text: t(:"items.show.#{type}_#{link[:section] ? 'section_item' : 'item'}"),
        type:,
        icon: link.fetch(:icon),
        arrow_icon: type == 'prev' ? 'arrow-left' : 'arrow-right',
      }
    end
  end
end
