# frozen_string_literal: true

module Pinboard
  class Topic < ApplicationComponent
    include PinboardRoutesHelper

    def initialize(topic, course_code)
      @topic = topic
      @course_code = course_code
    end

    def css_classes
      %w[pinboard-question].tap do |cls|
        cls << 'sticky' if sticky?
        cls << (read? ? 'read' : 'unread')
      end.join(' ')
    end

    def title
      if blocked?
        "#{t(:'pinboard.reporting.blocked')} #{@topic.title}"
      else
        @topic.title
      end
    end

    def blocked?
      %w[blocked auto_blocked].include? @topic.workflow_state
    end

    def sticky?
      @topic.sticky
    end

    def url
      question_path(url_params)
    end

    def votes
      @topic.votes_sum
    end

    def views
      @topic.watches.size
    end

    def reply_count
      @topic.public_answers_count.to_i +
        @topic.public_comments_count.to_i +
        @topic.public_answer_comments_count.to_i
    end

    def answered?
      @topic.accepted_answer_id.present?
    end

    def closed?
      @topic.closed
    end

    def read?
      @topic.user_watch.present? && (@topic.updated_at < @topic.user_watch.updated_at)
    end

    def tags
      [user_tags, implicit_tags].flatten.compact
    end

    def time_ago
      time_ago_in_words(@topic.updated_at)
    end

    private

    def url_params
      {course_id: @course_code, id: @topic.id}
    end

    def user_tags
      @topic.explicit_tags.map {|tag| {name: tag.name, id: tag.id} }
    end

    def implicit_tags
      # referenced resource can be a Xikolo::Course::Section or a Xikolo::Course::Item
      resource_types = {
        'Xikolo::Course::Section' => CourseService::Section,
        'Xikolo::Course::Item' => CourseService::Item,
      }
      @topic.implicit_tags.map do |tag|
        resource_class = resource_types[tag.referenced_resource]
        if resource_class
          {name: resource_class.find(tag.name).title, id: tag.id}
        else
          {name: tag.name, id: tag.id}
        end
      end
    end
  end
end
