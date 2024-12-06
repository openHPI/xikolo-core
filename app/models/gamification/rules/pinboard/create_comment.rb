# frozen_string_literal: true

module Gamification
  module Rules
    module Pinboard
      class CreateComment < Gamification::Rules::Base
        def create_score!
          # Do not award points for comments in the "Technical issues" sections
          return if @payload.fetch(:technical)

          super
        end

        private

        def name
          :create_comment
        end

        def checksum
          @payload.fetch :id
        end

        def data
          {comment_id: @payload.fetch(:id)}
        end

        def required_keys
          %i[course_id id user_id]
        end
      end
    end
  end
end
