# frozen_string_literal: true

module ItemStats
  class VideoItemStats < BaseStats
    def initialize(item)
      super

      @stats_promise = lanalytics_api.rel(:metric).get(
        name: 'video_statistics',
        item_id: item['id']
      )
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

    def render(ctx)
      ctx.render('course/admin/item_stats/video', item_stats: self)
    end

    def event_mapping
      %w[play pause seek_start change_speed].map do |verb|
        {
          x: {
            type: 'collect',
            sourceKey: 'time',
          },
          y: {
            type: 'collect',
            sourceKey: verb,
          },
          name: {
            type: 'constant',
            value: verb.titleize,
          },
        }
      end.to_json
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
