# frozen_string_literal: true

module Gamification
  module Rules
    module Pinboard
      class UpvoteQuestion < Gamification::Rules::Base
        def create_score!
          # You don't get points for upvoting your own question
          return if receiver == @payload.fetch(:user_id)

          # You only get points for positive votes
          return unless vote_value > 0

          super
        end

        private

        def name
          :upvote_question
        end

        def checksum
          @payload.fetch :votable_id
        end

        def data
          {votable_id: @payload.fetch(:votable_id)}
        end

        def vote_value
          @payload.fetch(:value).to_i
        end

        def receiver
          @payload.fetch :votable_user_id
        end

        def required_keys
          %i[course_id id votable_id votable_user_id]
        end
      end
    end
  end
end
