# frozen_string_literal: true

module ItemStats
  class QuizItemStats < BaseStats
    def initialize(item)
      super

      @item = item
      @quiz_promise = quiz_api.rel(:quiz).get({id: item['content_id']})
      @stats_promise = quiz_api.rel(:submission_statistic).get({
        id: item['content_id'],
        embed: 'avg_submit_duration',
      })
    end

    def facts
      facts = [
        I18n.t(
          'course.admin.item_stats.quiz.submissions',
          submissions: stats['total_submissions'],
          users: stats['total_submissions_distinct']
        ),
      ]

      unless quiz['unlimited_time']
        facts << I18n.t(
          'course.admin.item_stats.quiz.time',
          seconds: stats['avg_submit_duration'].ceil,
          limit: quiz['time_limit_seconds']
        )
      end

      if @item['exercise_type'] != 'survey'
        percentage_avg = format(
          '%.2f',
          stats['avg_points'] / stats['max_points'] * 100
        )

        facts << I18n.t(
          'course.admin.item_stats.quiz.points',
          avg: format('%.2f', stats['avg_points']),
          percentage_avg:,
          max_points: stats['max_points']
        )
      end

      facts.map(&:html_safe)
    end

    def facts_icon
      'money-check-pen'
    end

    private

    def stats
      @stats ||= @stats_promise.value!
    end

    def quiz
      @quiz ||= @quiz_promise.value!
    end

    def quiz_api
      @quiz_api ||= Xikolo.api(:quiz).value!
    end
  end
end
