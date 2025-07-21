# frozen_string_literal: true

module Xikolo
  module Entities
    class PinboardSubscription < Grape::Entity
      include Rails.application.routes.url_helpers
      include PinboardRoutesHelper

      expose :id

      expose def userId
        object.user_id
      end

      expose def questionId
        object.question_id
      end

      expose def createdAt
        object.created_at
      end

      expose def questionTitle
        object[:question_title]
      end

      expose def questionUpdatedAt
        object.question_updated_at
      end

      expose def courseId
        object.course_id
      end

      expose def link
        question_path(
          id: object['question_id'],
          course_id: short_id(object['course_id']),
          section_id:
        )
      end

      def short_id(course_id)
        Rails.cache.fetch("course.id2code.v1.#{course_id}", expires_in: 31.days) do
          ::Course::Course.find(course_id).course_code
        rescue ActiveRecord::RecordNotFound
          UUID(course_id).to_param
        end
      end

      private

      def in_section_context?
        @section_id.present?
      end

      def section_id
        return @section_id if defined? @section_id

        section_tag = object['implicit_tags']
          &.find {|tag| tag['referenced_resource'] == 'Xikolo::Course::Section' }
        @section_id = if section_tag
                        UUID(section_tag['name']).to_param
                      elsif object['implicit_tags']
                          &.find {|tag| tag['name'] == 'Technical Issues' }
                        'technical_issues'
                      end
      end
    end
  end
end
