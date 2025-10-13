# frozen_string_literal: true

module Admin
  module Statistics
    class Videos < ApplicationOperation
      def initialize(course_id: nil)
        super()

        @course_id = course_id
      end

      def call
        videos_data = fetch_videos_data(@course_id)
        return [] if videos_data.blank?

        {
          headers: {
            title: I18n.t('admin.statistics.videos.item_title_header'),
            position: I18n.t('admin.statistics.videos.position_header'),
            plays: I18n.t('admin.statistics.videos.plays_header'),
            duration: I18n.t('admin.statistics.videos.duration_header'),
            avg_farthest_watched: I18n.t(
              'admin.statistics.videos.avg_farthest_watched_header'
            ),
            forward_seeks: I18n.t('admin.statistics.videos.forward_seeks_header'),
            backward_seeks: I18n.t('admin.statistics.videos.backward_seeks_header'),
            actions: I18n.t('admin.statistics.videos.actions_header'),
          },
          videos_data: videos_data,
        }
      end

      private

      def fetch_videos_data(course_id)
        fetch_metric(name: 'video_statistics', course_id:).value!
      end

      def fetch_metric(name:, **params)
        return lanalytics_api.rel(:metric).get({**params, name:}) if metrics_available?(name)

        Restify::Promise.fulfilled(nil)
      end

      def metrics_available?(*names)
        names.map(&:underscore).all? {|name| available_metrics.include?(name) }
      end

      def available_metrics
        @available_metrics ||= begin
          metrics_list = lanalytics_api.rel(:metrics).get.value!
          metrics_list.select {|metric| metric['available'] }.pluck('name')
        end
      end

      def lanalytics_api
        @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
      end
    end
  end
end
