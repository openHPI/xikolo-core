# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class TakeSelftest < Gamification::Rules::Base
        def create_score!
          # Do not check for rule_active here, as this might be required to trigger other rules (e.g. attended_section).
          # Set the minimum required points--that have to be achieved in a selftest to make it count
          # --in the config file. We suggest 1 as a reasonable amount.
          return unless enough_selftest_points?

          super

          Gamification::Rules::Course::AttendedSection.new(@payload).create_score!

          Gamification::Rules::Course::SelftestMaster.new(@payload).create_score!
        end

        private

        def name
          :take_selftest
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

        def enough_selftest_points?
          selftest_points >= config_param(:min_result)
        end

        def selftest_points
          @payload.fetch(:points)
        end
      end
    end
  end
end
