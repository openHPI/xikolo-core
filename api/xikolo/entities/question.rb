# frozen_string_literal: true

module Xikolo
  module Entities
    class Question < Grape::Entity
      expose def id
        object['id']
      end

      expose def points
        object['points']
      end

      expose def type
        object['type']
      end

      expose def text
        object['text']
      end

      expose def courseId
        object['course_id']
      end

      expose def quizId
        object['quiz_id']
      end

      expose def referenceLink
        object['reference_link']
      end

      expose def answers
        object['answers'].pluck('id')
      end
    end
  end
end
