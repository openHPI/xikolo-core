# frozen_string_literal: true

module Xikolo
  module V2::CourseItems
    class LtiExercises < Xikolo::Endpoint::CollectionEndpoint
      entity do
        type 'lti-exercises'

        attribute('instructions') {
          description 'A text with detailed explanation what this task will entail'
          type :string
        }

        attribute('weight') {
          description 'A multiplier (integer) for the LTI score (a number between 0 and 1) to achieve the final score for this exercise'
          type :integer
        }

        attribute('allowed_attempts') {
          description 'The maximum number of attempts allowed per user (0 is infinite)'
          type :integer
        }

        attribute('launch_url') {
          description 'URL to launch the LTI tool'
          type :string
          reading {|exercise|
            next unless exercise.lti_provider_id

            item = ::Course::Item.find_by(content_id: exercise.id)
            course_id = item&.section&.course_id
            Xikolo::V2::URL.tool_launch_course_item_url UUID4(course_id), UUID4(item.id)
          }
        }
      end

      member do
        get 'Retrieve information about a LTI exercise' do
          authenticate!

          item = ::Course::Item.find_by(content_id: id)
          course = item&.section&.course
          not_found! unless item&.available? && course.present?

          in_context course.context_id

          # Check if user has admin permissions or is enrolled to the course
          any_permission!('course.content.access', 'course.content.access.available')

          ::Lti::Exercise.find(UUID4(id).to_s)
        end
      end
    end
  end
end
