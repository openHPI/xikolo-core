# frozen_string_literal: true

module Xikolo
  module Entities
    class Thread < Grape::Entity
      include Rails.application.routes.url_helpers
      include PinboardRoutesHelper

      expose :id
      expose :title

      expose def abstract
        object.text[0..200].gsub(/\s\w+\s*$/, '...')
      end

      expose def teaser
        ''
      end

      expose :sticky

      expose def createdAt
        object.created_at
      end

      expose def updatedAt
        object.updated_at
      end

      expose :views
      expose :votes

      expose def replyCount
        object.answer_count + object.comment_count + object.answer_comment_count
      end

      expose def isClosed
        object.closed
      end

      expose def isRead
        object.read
      end

      expose def isAnswered
        !object.accepted_answer_id.nil?
      end

      expose def isBlocked
        %w[blocked auto_blocked].include? object.abuse_report_state
      end

      expose :urls do
        expose :deeplink
      end

      expose def course
        object.course_id
      end

      expose def tags
        user_tags + implicit_tags
      end

      def deeplink
        question_path(
          id: object.id,
          course_id: options[:course_code],
          section_id: options[:section_id]
        )
      end

      private

      def user_tags
        object.user_tags.filter_map {|name|
          options[:tags].find {|tag| tag.name == name }
        }.map(&:id)
      end

      def implicit_tags
        object.implicit_tags.filter_map {|implicit_tag|
          options[:tags].find {|tag| tag.name == implicit_tag['name'] }
        }.map(&:id)
      end

      def in_section_context?
        options[:section_id].present?
      end
    end
  end
end
