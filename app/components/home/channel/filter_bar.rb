# frozen_string_literal: true

module Home
  module Channel
    class FilterBar < ApplicationComponent
      include Home::SharedCourseFilters

      def initialize(user: nil, results_count: nil)
        @user = user
        @results_count = results_count
      end

      private

      def filters
        @filters ||= [
          language_filter,
          format_filter(::Catalog::Course.released.for_channel_list(channel)),
          *cluster_filters,
        ].compact
      end

      def channel
        @channel ||= ::CourseService::Channel.by_identifier(params[:id]).take
      end
    end
  end
end
