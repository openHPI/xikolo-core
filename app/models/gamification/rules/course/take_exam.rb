# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class TakeExam < Gamification::Rules::Base
        def create_score!
          # Do not check for rule_active? here, as this might be required to trigger other rules (e.g. attended_section)
          return unless @payload[:submission_deadline]

          super

          Gamification::Rules::Course::AttendedSection.new(@payload).create_score!

          Gamification::Rules::Course::SelftestMaster.new(@payload).create_score!
        end

        private

        def name
          :take_exam
        end

        def required_keys
          %i[course_id item_id section_id id user_id]
        end

        def checksum
          @payload.fetch :id
        end

        def data
          {
            result_id: @payload.fetch(:id),
            item_id: @payload.fetch(:item_id),
            section_id: @payload.fetch(:section_id),
          }
        end
      end
    end
  end
end
