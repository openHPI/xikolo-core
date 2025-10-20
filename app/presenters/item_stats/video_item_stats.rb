# frozen_string_literal: true

module ItemStats
  class VideoItemStats < BaseStats
    def initialize(item)
      super

      @stats_promise = lanalytics_api.rel(:metric).get({
        name: 'video_statistics',
        item_id: item['id'],
      })
    end

    def facts
      [
        I18n.t(
          'course.admin.item_stats.video.plays',
          plays: stats['plays']
        ),
        I18n.t(
          'course.admin.item_stats.video.farthest_watched',
          farthest_watched: format('%.2f', stats['avg_farthest_watched'] * 100)
        ),
        I18n.t(
          'course.admin.item_stats.video.forward_seeks',
          seeks: stats['forward_seeks']
        ),
        I18n.t(
          'course.admin.item_stats.video.backward_seeks',
          seeks: stats['backward_seeks']
        ),
      ].map(&:html_safe)
    end

    def facts_icon
      'video'
    end

    private

    def stats
      @stats ||= @stats_promise.value!
    end

    def lanalytics_api
      @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
    end
  end
end
