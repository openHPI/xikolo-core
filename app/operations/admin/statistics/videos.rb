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
        headers = {
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
        }
        return {headers:, videos_data: []} if videos_data.blank?

        {
          headers:,
          videos_data: format_videos_data(videos_data),
        }
      end

      private

      def fetch_videos_data(course_id)
        fetch_metric(name: 'video_statistics', course_id:).value!
      rescue StandardError
        nil
      end

      def fetch_metric(name:, **params)
        return Restify::Promise.fulfilled(nil) unless metrics_available?(name)

        api = lanalytics_api
        return Restify::Promise.fulfilled(nil) unless api

        api.rel(:metric).get({**params, name:})
      end

      def metrics_available?(*names)
        names.map(&:underscore).all? {|name| available_metrics.include?(name) }
      end

      def available_metrics
        @available_metrics ||= begin
          api = lanalytics_api
          if api
            metrics_list = api.rel(:metrics).get.value!
            metrics_list.select {|metric| metric['available'] }.pluck('name')
          else
            []
          end
        rescue StandardError
          []
        end
      end

      def lanalytics_api
        @lanalytics_api ||= begin
          Xikolo.api(:learnanalytics).value!
        rescue StandardError
          nil
        end
      end

      def format_videos_data(videos_data)
        videos_data.map do |row|
          {
            'title' => row['title'],
            'position' => row['position'],
            'plays' => row['plays'],
            'duration' => format_duration(row['duration']),
            'avg_farthest_watched' => format_percentage(row['avg_farthest_watched']),
            'forward_seeks' => row['forward_seeks'],
            'backward_seeks' => row['backward_seeks'],
            'actions' => row['id'],
          }
        end
      end

      def format_duration(seconds)
        return '0:00' unless seconds

        minutes = seconds.to_i / 60
        seconds = seconds.to_i % 60
        format('%02d:%02d', minutes, seconds)
      end

      def format_percentage(value)
        value ? format('%.1f%%', value.to_f * 100) : '0%'
      end
    end
  end
end
