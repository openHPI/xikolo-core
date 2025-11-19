# frozen_string_literal: true

module Admin
  module Statistics
    module Course
      class VideoPlays < ApplicationOperation
        include MetricHelpers

        def initialize(course_id:)
          super()

          @course_id = course_id
        end

        def call
          return {} if course_id.blank?

          fetch_metric(name: 'video_play_count', course_id:).value! || {}
        end

        private

        attr_reader :course_id
      end
    end
  end
end
