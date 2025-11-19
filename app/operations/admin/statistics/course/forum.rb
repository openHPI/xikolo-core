# frozen_string_literal: true

module Admin
  module Statistics
    module Course
      class Forum < ApplicationOperation
        include MetricHelpers

        def initialize(course_id:)
          super()

          @course_id = course_id
        end

        def call
          return {} if course_id.blank?

          Restify::Promise.new([
            pinboard_api.rel(:statistic).get({id: course_id}),
            fetch_metric(name: 'forum_activity', course_id: course_id),
            fetch_metric(name: 'forum_write_activity', course_id: course_id),
          ]) do |forum_statistics, forum_activity, forum_write_activity|
            {
              forum_statistics: forum_statistics || {},
              forum_activity: forum_activity || {},
              forum_write_activity: forum_write_activity || {},
            }
          end.value! || {}
        end

        private

        attr_reader :course_id
      end
    end
  end
end
