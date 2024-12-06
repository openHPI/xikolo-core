# frozen_string_literal: true

module Gamification
  module Rules
    module Pinboard
      class AcceptedAnswer < Gamification::Rules::Base
        def create_score!
          # Do not award points for answers in the "Technical issues" sections
          return if @payload.fetch(:technical)

          # If the question has no accepted answer, this rule does not become active
          return unless @payload.fetch(:accepted_answer_id)

          # If the accepted answer was created by the question author, do not award points
          return if @payload[:user_id] == @payload[:accepted_answer_user_id]

          super
        end

        private

        def name
          :accepted_answer
        end

        def checksum
          @payload.fetch :accepted_answer_id
        end

        def data
          {accepted_answer_id: @payload.fetch(:accepted_answer_id)}
        end

        def receiver
          @payload.fetch :accepted_answer_user_id
        end

        def required_keys
          %i[course_id id accepted_answer_user_id]
        end
      end
    end
  end
end
