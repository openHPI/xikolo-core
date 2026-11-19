# frozen_string_literal: true

module Home
  module Course
    class FilterBar < ApplicationComponent
      include Home::SharedCourseFilters

      def initialize(user: nil, results_count: nil)
        @user = user
        @results_count = results_count
      end

      private

      def filters
        @filters ||= [
          channel_filter,
          language_filter,
          format_filter(::Catalog::Course.released.for_global_list),
          *cluster_filters,
        ].compact
      end

      def channel_filter
        channels = ::CourseService::Channel.where(public: true, affiliated: false, archived: false)
          .to_h {|channel| [channel.title, channel.code] }

        return if channels.empty?

        Global::FilterBar::Filter.new(:channel, t(:'course.courses.index.filter.channel'), channels,
          selected: params[:channel])
      end
    end
  end
end
