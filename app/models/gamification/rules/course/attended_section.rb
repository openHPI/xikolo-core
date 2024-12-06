# frozen_string_literal: true

module Gamification
  module Rules
    module Course
      class AttendedSection < Gamification::Rules::Base
        def create_score!
          # To completely deactivate this rule, remove it from the config file
          return unless active?

          return unless continuously_attended_section?

          super

          Gamification::Rules::Course::ContinuousAttendance.new(@payload).create_score!
        end

        private

        def name
          :attended_section
        end

        def checksum
          @payload.fetch :section_id
        end

        def data
          {section_id: @payload.fetch(:section_id)}
        end

        def continuously_attended_section?
          (video_items_visited_percentage > 70) &&
            score_for_rule_in_section?(:take_exam) &&
            score_for_rule_in_section?(:take_selftest)
        end

        def video_items_visited_percentage
          return 0 if visited_item_scores.empty?
          return 0 if video_items_total == 0

          (video_items_visited * 100) / video_items_total
        end

        def score_for_rule_in_section?(rule)
          matching_scores_for(rule).any? do |score|
            @payload.fetch(:section_id) == score.data[:section_id]
          end
        end

        def visited_item_scores
          @visited_item_scores ||= matching_scores_for(:visited_item)
        end

        def matching_scores_for(rule)
          Gamification::Score.where(
            user_id: receiver,
            course_id:,
            rule:
          )
        end

        def section_items
          Xikolo.api(:course).value!.rel(:items).get(
            section_id: @payload.fetch(:section_id)
          ).value!
        end

        def video_item_ids
          @video_item_ids ||= section_items.select do |item|
            item['content_type'] == 'video'
          end.pluck('id')
        end

        def video_items_total
          video_item_ids.count
        end

        def video_items_visited
          visited_item_scores.count {|score| video_item_ids.include? score.data[:item_id] }
        end
      end
    end
  end
end
