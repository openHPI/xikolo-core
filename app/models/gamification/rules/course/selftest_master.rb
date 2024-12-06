# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class SelftestMaster < Gamification::Rules::Base
        def create_score!
          return unless active?

          return unless first_time?

          super
        end

        private

        def name
          :selftest_master
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

        def first_time?
          mastered? && unrewarded?
        end

        def mastered?
          @payload[:exercise_type] == 'selftest' && result_points == result_max_points
        end

        def result_points
          @payload.fetch :points
        end

        def result_max_points
          @payload.fetch :max_points
        end

        def unrewarded?
          scores_for_selftest = Gamification::Score.where(
            user_id: receiver,
            course_id:,
            rule: name
          )

          scores_for_selftest.all? {|score| score.data[:item_id] != @payload.fetch(:item_id) }
        end
      end
    end
  end
end
