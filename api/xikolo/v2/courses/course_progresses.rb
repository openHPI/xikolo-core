# frozen_string_literal: true

module Xikolo
  module V2::Courses
    class CourseProgresses < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'course-progresses'

        id {|progress|
          progress['resource_id']
        }

        attribute('main_exercises') {
          description 'The course\'s main exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['main_exercises']
          }
        }

        attribute('selftest_exercises') {
          description 'The course\'s selftest exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['selftest_exercises']
          }
        }

        attribute('bonus_exercises') {
          description 'The course\'s bonus exercise statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.exercise_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.exercise_data progress['bonus_exercises']
          }
        }

        attribute('visits') {
          description 'The course\'s item visit statistics for user'
          type :hash, of: Xikolo::V2::ProgressStats.visit_schema
          reading {|progress|
            Xikolo::V2::ProgressStats.visit_data progress['visits']
          }
        }

        includable has_many('section_progresses', Xikolo::V2::Courses::SectionProgresses) {
          embedded {|res| res['section_progresses'] }
        }
      end

      member do
        get 'Get course progress' do
          authenticate!

          progresses = Xikolo.api(:course).value!.rel(:progresses).get({
            user_id: current_user.id,
            course_id: id,
          }).value!

          # only return course progress
          course_progress = progresses.pop

          # performance workaround, to not fetch all progresses twice
          progresses.each {|p| p['course_id'] = id }
          course_progress['section_progresses'] = progresses

          course_progress
        end
      end
    end
  end
end
