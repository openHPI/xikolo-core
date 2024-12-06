# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class SectionProgresses < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'section-progresses'

        id {|progress|
          progress['resource_id']
        }

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

        attribute('available') {
          description 'Whether the section was unlocked yet'
          type :boolean
        }

        attribute('parent') {
          description 'Whether the section is a parent section'
          type :boolean
        }

        attribute('main_exercises') {
          description 'The sections\'s main exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['main_exercises']
          }
        }

        attribute('selftest_exercises') {
          description 'The sections\'s selftest exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['selftest_exercises']
          }
        }

        attribute('bonus_exercises') {
          description 'The sections\'s bonus exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['bonus_exercises']
          }
        }

        attribute('visits') {
          description 'The sections\'s item visit statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.visit_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.visit_data progress['visits']
          }
        }

        attribute('items') {
          description 'The sections\'s item visit statistics for user'
          type :array, of: nested_type(:hash, of: Xikolo::V2::ProgressStats.item_schema)
          reading {|progress|
            progress['items']&.map do |item|
              Xikolo::V2::ProgressStats.item_data item
            end
          }
        }

        has_one('course_progress', Xikolo::V2::Courses::CourseProgresses) {
          foreign_key 'course_id'
        }
      end

      filters do
        required('course') {
          description 'Only return sections belonging to the course with this UUID'
          alias_for 'course_id'
        }
      end

      collection do
        get 'List all section progresses for a given course' do
          authenticate!

          progresses = Xikolo.api(:course).value!.rel(:progresses).get(
            filters.merge('user_id' => current_user.id)
          ).value!

          # remove course progress
          progresses.pop

          progresses.each {|p| p['course_id'] = filters['course_id'] }

          # return progresses of sections
          progresses
        end
      end
    end
  end
end
