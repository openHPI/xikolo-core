# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class ContinuousAttendance < Gamification::Rules::Base
        def create_score!
          return unless attended_previous_section?

          return if score_for_section_exists?

          super
        end

        private

        def name
          :continuous_attendance
        end

        def points
          return super if collected_scores_count >= min_scores_count

          0 # Points for attending a section are already provided elsewhere
        end

        def checksum
          @payload.fetch :section_id
        end

        def data
          {section_id: @payload.fetch(:section_id)}
        end

        def collected_scores_count
          Gamification::Score.where(
            user_id: @payload.fetch(:user_id),
            course_id: @payload.fetch(:course_id),
            rule: name
          ).count
        end

        def min_scores_count
          config_param(:min)
        end

        def attended_previous_section?
          course_section_ids = Xikolo.api(:course).value!.rel(:sections).get({
            course_id: @payload.fetch(:course_id),
          }).value!.pluck('id')

          scores = Gamification::Score.where(
            user_id: receiver,
            course_id:,
            rule: :attended_section
          )

          scores.any? do |score|
            new_section_index = course_section_ids.index(@payload.fetch(:section_id))
            scored_section_index = course_section_ids.index(score.data[:section_id])

            new_section_index && scored_section_index && new_section_index - 1 == scored_section_index
          end
        end

        def score_for_section_exists?
          existing_scores = Gamification::Score.where(
            user_id: receiver,
            course_id:,
            rule: name
          )

          existing_scores.any? do |score|
            @payload.fetch(:section_id) == score.data[:section_id]
          end
        end
      end
    end
  end
end
