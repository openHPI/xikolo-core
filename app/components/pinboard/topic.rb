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
        "#{t(:'pinboard.reporting.blocked')} #{@topic['title']}"
      else
        @topic['title']
      end
    end

    def blocked?
      %w[blocked auto_blocked].include? @topic['abuse_report_state']
    end

    def sticky?
      @topic['sticky']
    end

    def url
      question_path(url_params)
    end

    def votes
      @topic['votes']
    end

    def views
      @topic['views']
    end

    def reply_count
      [@topic['answer_count'], @topic['comment_count'], @topic['answer_comment_count']].sum(&:to_i)
    end

    def answered?
      @topic['accepted_answer_id'].present?
    end

    def closed?
      @topic['closed']
    end

    def read?
      @topic['read']
    end

    def tags
      [user_tags, implicit_tags].flatten.compact
    end

    def time_ago
      time_ago_in_words(@topic['updated_at'])
    end

    private

    def url_params
      {
        course_id: @course_code, id: @topic['id']
      }.tap do |h|
        h[:learning_room_id] = @topic['learning_room_id'] if @topic['learning_room_id'].present?
        h[:section_id] = @topic['section_id'] if @topic['section_id'].present?
      end
    end

    def user_tags
      return if @topic['user_tags'].blank?

      @topic['user_tags'].map(&:to_h).map do |h|
        h.transform_keys(&:to_sym)
      end
    end

    def implicit_tags
      return if @topic['implicit_tags'].blank?

      implicit_tags_collection = []
      # referenced resource can be a Xikolo::Course::Section or a Xikolo::Course::Item
      resource_types = %w[Xikolo::Course::Section Xikolo::Course::Item]

      @topic['implicit_tags'].each do |tag|
        if resource_types.include? tag['referenced_resource']
          section = tag['referenced_resource'].constantize.find tag['name']
          Acfs.run
          implicit_tags_collection << {name: section.title, id: tag['id']}
        else
          implicit_tags_collection << {name: tag['name'], id: tag['id']}
        end
      end

      implicit_tags_collection
    end
  end
end
