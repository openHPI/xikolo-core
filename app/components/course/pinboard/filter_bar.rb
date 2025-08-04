# frozen_string_literal: true

module Course
  module Pinboard
    class FilterBar < ApplicationComponent
      def initialize(tags: nil)
        @tags = tags
      end

      private

      def action
        course_pinboard_index_path(params[:course_id])
      end

      def filters
        @filters ||= [
          tags_filter,
          order_filter,
        ].compact
      end

      def tags_filter
        return if @tags.blank?

        Global::FilterBar::Filter.new(:tags, t(:'pinboard.index.filter.tags.label'), tags_options,
          selected: params[:tags], multi_select: true, blank_option: t(:'pinboard.index.filter.tags.placeholder'))
      end

      def tags_options
        tags = @tags.map {|tag| [tag.name, tag.id] }

        # Add a fallback tag if they are specified in params
        # We allow users to select tags that are not in the list
        # by clicking on question info tags.
        # See: app/assets/course/pinboard/filter.ts
        missing_tag_ids = Array(params[:tags]) - @tags.map {|tag| tag.id.to_s }
        missing_tag_ids.each do |missing_id|
          tags << [t(:'pinboard.index.filter.tags.missing'), missing_id]
        end

        tags
      end

      def order_filter
        available_orders = %w[age votes]
        orders = available_orders.map do |order|
          [t(:"pinboard.index.filter.sort.#{order}"), order]
        end

        Global::FilterBar::Filter.new(:order, t(:'pinboard.index.filter.order'), orders,
          selected: params[:order], blank_option: t(:'pinboard.index.filter.sort.activity'))
      end
    end
  end
end
