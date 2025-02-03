# frozen_string_literal: true

module Course
  class BottomNavigation < ApplicationComponent
    def initialize(course_id:, prev_item_id:, next_item_id:)
      @course_id = course_id
      @prev_item_id = prev_item_id
      @next_item_id = next_item_id
    end

    def render?
      @prev_item_id || @next_item_id
    end

    def items
      [
        item_data(@prev_item_id, 'prev').presence,
        item_data(@next_item_id, 'next').presence,
      ].compact
    end

    private

    def item_data(item_id, type)
      return if item_id.blank?

      item = Item.find(item_id)
      {
        url: course_item_path(@course_id, item.id),
        title: item.title,
        text: t(:"items.show.#{type}_item"),
        icon: Item::Icon.from_resource(item).icon_class,
        arrow_icon: type == 'prev' ? 'chevron-left' : 'chevron-right',
        data: {tooltip: item.title, 'lanalytics-event': {verb: "navigated_#{type}_item"}},
        css_modifier: "bottom-navigation__item--#{type}",
      }
    rescue ActiveRecord::RecordNotFound
      # do nothing
    end
  end
end
