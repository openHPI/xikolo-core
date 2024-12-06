# frozen_string_literal: true

module ItemTypes
  class Quiz < Base
    attr_reader :quiz, :questions

    def initialize(quiz, questions)
      super()

      @quiz = quiz
      @questions = questions
    end

    def time_effort
      general_thinking_time + decision_time + free_text_answer_time
    end

    private

    SELECT_MULTIPLE = 'Xikolo::Quiz::MultipleAnswerQuestion'
    SELECT_ONE = 'Xikolo::Quiz::MultipleChoiceQuestion'
    FREE_TEXT = 'Xikolo::Quiz::FreeTextQuestion'
    ESSAY = 'Xikolo::Quiz::EssayQuestion'

    def general_thinking_time
      # 10 seconds (thinking + navigation) general thinking per question
      questions.count * 10
    end

    def decision_time
      # Total time for making a decision depending on type
      # With typical number of answers results in 48/24 seconds per question
      # (not including the general thinking time nor reading time)
      questions.filter_map do |question|
        next unless [SELECT_MULTIPLE, SELECT_ONE].include? question['type']

        question_decisions(question) * 2
      end.sum
    end

    def free_text_answer_time
      # Free text questions are estimated with 60 seconds
      questions.pluck('type').count do |type|
        [FREE_TEXT, ESSAY].include? type
      end * 60
    end

    def question_decisions(question)
      # The time needed for deciding which answer to choose depends
      # on the number of answers and the question type.
      # Typically four answers per question
      # Select multiple: 6 * 4 = 24 (seconds)
      # Select one: 3 * 4 = 12 (seconds)
      type_difficulty(question['type']) * question['answers'].count
    end

    def type_difficulty(type)
      case type
        when SELECT_MULTIPLE
          6
        when SELECT_ONE
          3
        else
          0
      end
    end
  end
end
