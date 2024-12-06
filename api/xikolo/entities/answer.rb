# frozen_string_literal: true

module Xikolo
  module Entities
    class Answer < Grape::Entity
      expose def id
        object['id']
      end

      expose def correct
        object['correct']
      end

      expose def text
        object['text']
      end
    end
  end
end
