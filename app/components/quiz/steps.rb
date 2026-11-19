# frozen_string_literal: true

module Quiz
  class Steps < ApplicationComponent
    def initialize(questions, statuses: {})
      @questions = questions
      @statuses = statuses
    end

    private

    def status_icon(question)
      case @statuses[question.id]
        when 'correct' then helpers.pixelart_icon('check', css_class: 'x-step-icon')
        when 'incorrect' then helpers.pixelart_icon('close', css_class: 'x-step-icon')
      end
    end

    def status_class(question)
      case @statuses[question.id]
        when 'correct' then 'x-step-success'
        when 'incorrect' then 'x-step-error'
      end
    end
  end
end
