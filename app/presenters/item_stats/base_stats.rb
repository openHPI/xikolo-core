# frozen_string_literal: true

module ItemStats
  class BaseStats
    def initialize(item)
      @item = item
    end

    def base_facts
      []
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

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end
  end
end
