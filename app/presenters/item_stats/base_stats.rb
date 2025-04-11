# frozen_string_literal: true

module ItemStats
  class BaseStats
    def initialize(item)
      @item = item
      @base_stats_promise = lanalytics_api.rel(:metric).get({
        name: 'item_visits',
        resource_id: item['id'],
      })
    end

    def base_facts
      [
        I18n.t(
          'course.admin.item_stats.facts.visits',
          visits: base_stats['total_item_visits'],
          users: base_stats['users_visited']
        ),
        I18n.t(
          'course.admin.item_stats.facts.visits_last_24h',
          visits: base_stats['total_item_visits_24'],
          users: base_stats['users_visited_24']
        ),
      ].map(&:html_safe)
    end

    def facts
      []
    end

    def facts_icon
      'chart-mixed'
    end

    def nav
      ItemStatsPresenter.nav_elements(course, @item)
    end

    def item_id
      @item['id']
    end

    def content_type
      @item['content_type']
    end

    def course_code
      course['course_code']
    end

    def course_id
      course['id']
    end

    protected

    def course
      @course ||= course_api.rel(:course).get({id: @item['course_id']}).value!
    end

    def base_stats
      @base_stats ||= @base_stats_promise.value!
    end

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end

    def lanalytics_api
      @lanalytics_api ||= Xikolo.api(:learnanalytics).value!
    end
  end
end
