# frozen_string_literal: true

module ItemStats
  class RichTextItemStats < BaseStats
    def initialize(item)
      super

      @stats_promise = lanalytics_api.rel(:metric).get(
        name: 'rich_text_link_click_count',
        course_id: item['course_id'],
        item_id: item['id']
      )
    end

    def facts
      facts = [
        I18n.t(
          'course.admin.item_stats.rich_text.total_clicks',
          clicks: stats['total_clicks'],
          users: stats['total_clicks_unique_users']
        ),
      ]

      if stats['total_clicks'] > 0
        facts << I18n.t(
          'course.admin.item_stats.rich_text.earliest_click',
          date: I18n.l(
            Time.zone.parse(stats['earliest_timestamp']),
            format: '%b %d, %Y %l:%M %p',
            locale: :en
          )
        )
        facts << I18n.t(
          'course.admin.item_stats.rich_text.latest_click',
          date: I18n.l(
            Time.zone.parse(stats['latest_timestamp']),
            format: '%b %d, %Y %l:%M %p',
            locale: :en
          )
        )
      end

      facts.map(&:html_safe)
    end

    def facts_icon
      'file-lines'
    end

    def render(ctx)
      ctx.render('course/admin/item_stats/rich_text', item_stats: self)
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
