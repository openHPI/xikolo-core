# frozen_string_literal: true

module QuizService
  class ApplicationDecorator < Draper::Decorator
    # Draper will use the main apps helper by default.
    def h
      super.quiz_service
    end
  end
end
