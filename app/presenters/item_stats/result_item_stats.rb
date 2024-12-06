# frozen_string_literal: true

# generic item stats for all items with results
module ItemStats
  class ResultItemStats < BaseStats
    def initialize(item)
      super

      @item = item
      @stats_promise = item.rel(:statistics).get
    end

    def facts
      percentage_avg = format(
        '%.2f',
        (stats['avg_points'] / stats['max_points'] * 100)
      )

      facts = [
        I18n.t(
          'course.admin.item_stats.result.submissions',
          submissions: stats['total_submissions'],
          users: stats['total_submissions_distinct']
        ),
        I18n.t(
          'course.admin.item_stats.result.perfect_submissions',
          submissions: stats['perfect_submissions'],
          users: stats['perfect_submissions_distinct']
        ),
        I18n.t(
          'course.admin.item_stats.result.points',
          avg: format('%.2f', stats['avg_points']),
          percentage_avg:,
          max_points: stats['max_points']
        ),
      ]

      facts.map(&:html_safe)
    end

    def facts_icon
      'money-check-pen'
    end

    def render(ctx)
      ctx.render(
        'course/admin/item_stats/result',
        item_stats: self
      )
    end

    def submissions?
      stats['total_submissions'].positive?
    end

    def submission_limit_exceeded?
      stats['total_submissions'] > submission_limit
    end

    def submission_limit
      Xikolo.config.quiz_item_statistics_submission_limit
    end

    def item_id
      @item['id']
    end

    private

    def stats
      @stats ||= @stats_promise.value!
    end
  end
end
