# frozen_string_literal: true

module Xikolo
  module V2
    module Endpoint
      class GetCourseTimeEffort < Xikolo::API
        desc 'Get time effort for current course'
        params do
          requires :course_id, type: String, desc: 'The course UUID'
        end
        get do
          published_items = Xikolo.api(:course).value!.rel(:items).get(
            course_id: params[:course_id],
            published: true,
            available: true,
            state_for: current_user.id
          ).value!

          exercises = %w[quiz lti_exercise]
          completed_items = published_items.select do |i|
            (exercises.include?(i['content_type']) &&
              %w[new visited].exclude?(i['user_state'])) ||
              (exercises.exclude?(i['content_type']) &&
                (i['user_state'] != 'new'))
          end.group_by {|i| i['content_type'] }

          published_items
            .group_by {|i| i['content_type'] }
            .each_with_object({}) do |(type, group_items), time_effort|
              all_time_efforts = group_items.pluck('time_effort')
              completed_time_efforts = completed_items.fetch(type, []).pluck('time_effort')
              time_effort[type] = {
                completed: completed_time_efforts.compact.sum {|t| t.fdiv(60).ceil },
                total: all_time_efforts.compact.sum {|t| t.fdiv(60).ceil },
                estimation_complete: all_time_efforts.none?(&:nil?),
              }
            end
        end
      end
    end
  end
end
