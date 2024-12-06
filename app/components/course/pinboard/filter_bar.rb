# frozen_string_literal: true

module Course
  module Pinboard
    class FilterBar < ApplicationComponent
      def initialize(tags: nil, within_collabspace: false)
        @tags = tags
        @within_collabspace = within_collabspace
      end

      private

      def action
        if @within_collabspace
          course_learning_room_pinboard_index_path(params[:course_id], params[:learning_room_id])
        else
          course_pinboard_index_path(params[:course_id])
        end
      end

      def filters
        @filters ||= [
          tags_filter,
          order_filter,
        ].compact
      end

      def tags_filter
        return if @tags.blank?

        tags = @tags.map do |tag|
          [tag.name, tag.id]
        end

        Global::FilterBar::Filter.new(:tags, t(:'pinboard.index.filter.tags.label'), tags,
          selected: params[:tags], multi_select: true, blank_option: t(:'pinboard.index.filter.tags.placeholder'))
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
