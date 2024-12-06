# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class VisitedItem < Gamification::Rules::Base
        def create_score!
          super

          Gamification::Rules::Course::AttendedSection.new(@payload).create_score!
        end

        private

        def name
          :visited_item
        end

        def required_keys
          %i[course_id item_id section_id id user_id]
        end

        def checksum
          @payload.fetch :id
        end

        def data
          {
            visit_id: @payload.fetch(:id),
            item_id: @payload.fetch(:item_id),
            section_id: @payload.fetch(:section_id),
          }
        end
      end
    end
  end
end
