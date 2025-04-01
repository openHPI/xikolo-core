# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class Sections < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'course-sections'

        attribute('title') {
          description 'The section\'s title'
          type :string
        }

        attribute('description') {
          description 'A text describing the section\'s content'
          type :string
        }

        attribute('position') {
          description 'The sections\'s position within its course'
          type :integer
        }

        attribute('start_at') {
          description 'The date when this section becomes available'
          type :datetime
          alias_for 'effective_start_date'
        }

        attribute('end_at') {
          description 'The date when access to this section is closed'
          type :datetime
          alias_for 'effective_end_date'
        }

        attribute('accessible') {
          description 'Whether the section\'s content can be accessed at this time'
          type :boolean
          reading {|section|
            if section['effective_start_date'] && Time.zone.parse(section['effective_start_date']).future?
              next false
            end

            if section['effective_end_date'] && Time.zone.parse(section['effective_end_date']).past?
              next false
            end

            true
          }
        }

        attribute('parent') {
          description 'Whether the section is a parent section of alternative sections'
          type :boolean
          reading {|section| section['alternative_state'] == 'parent' }
        }

        has_one('course', Xikolo::V2::Courses::Courses) {
          foreign_key 'course_id'
        }

        includable has_many('items', Xikolo::V2::Courses::Items) {
          filter_by 'section'
        }

        link('self') {|section| "/api/v2/course-sections/#{section['id']}" }
      end

      filters do
        required('course') {
          description 'Only return items belonging to the course with this UUID'
          alias_for 'course_id'
        }
      end

      collection do
        get 'List all sections for a given course' do
          block_courses_by('course_id') do
            Xikolo.api(:course).value!.rel(:sections).get(
              filters.merge({'published' => true})
            ).value!
          end
        end
      end

      member do
        get 'Retrieve information about a section' do
          block_access_by('course_id') do
            Xikolo.api(:course).value!.rel(:section).get({id:}).value!
          end
        end
      end
    end
  end
end
