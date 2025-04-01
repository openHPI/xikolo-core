# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class Dates < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'course-dates'

        id {|date|
          id = "#{date['course_id']}|#{date['type']}|#{date['resource_id']}"
          Digest::MD5.hexdigest id
        }

        attribute('type') {
          description 'The type of event (one of course_start, section_start, item_submission_publishing, item_submission_deadline)'
          type :string
        }

        attribute('title') {
          description 'The name of the referenced resource (a course, section or item)'
          type :string
        }

        attribute('date') {
          description 'Date and time when this event occurs'
          type :datetime
        }

        link('html') {|date|
          case date['resource_type']
            when 'section'
              Xikolo::V2::URL.course_section_path date['course_code'], UUID(date['resource_id']).to_param
            when 'item'
              Xikolo::V2::URL.course_item_path date['course_code'], UUID(date['resource_id']).to_param
            else
              Xikolo::V2::URL.course_path date['course_code']
          end
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }
      end

      filters do
        optional('course') {
          description 'Only return dates for the course with this UUID'
          alias_for 'course_id'
        }
      end

      collection do
        get 'Returns next course dates (assignments, deadlines etc.) relevant to the user' do
          authenticate!

          block_courses_by('course_id') do
            Xikolo.api(:course).value.rel(:next_dates).get(
              filters.merge({'user_id' => current_user.id})
            ).value!
          end
        end
      end
    end
  end
end
