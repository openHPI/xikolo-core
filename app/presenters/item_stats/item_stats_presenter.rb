# frozen_string_literal: true

module ItemStats
  class ItemStatsPresenter
    def self.for(item)
      case item['content_type']
        when 'video'
          VideoItemStats.new item
        when 'quiz'
          QuizItemStats.new item
        when 'rich_text'
          RichTextItemStats.new item
        when 'lti_exercise'
          ResultItemStats.new item
        else
          UnknownItemStats.new item
      end
    end

    def self.nav_elements(course, selected_item = nil)
      course_api = Xikolo.api(:course).value!

      sections = []
      Xikolo.paginate(
        course_api.rel(:sections).get(
          course_id: course['id'],
          include_alternatives: true
        )
      ) do |section|
        sections << section
      end

      items = []
      Xikolo.paginate(
        course_api.rel(:items).get(course_id: course['id'])
      ) do |i|
        section = sections.find {|s| s['id'] == i['section_id'] }

        section_title = section['title'].truncate(30)
        item_title = i['title'].truncate(60)

        items << {
          title: "#{section_title} - #{item_title} (#{i['content_type'].titleize})",
          url: Rails.application.routes.url_helpers
            .course_item_statistics_path(course_id: course['course_code'], item_id: i['id']),
          selected: i['id'] == selected_item&.dig('id'),
        }
      end

      items
    end
  end
end
