# frozen_string_literal: true

module QuizImporter
  class AnswerBuilder
    def self.build(text, correctness, explanation, question_type)
      clean_text = clean_string(text)

      if question_type == 'FreeText'
        correct = true
        exp = ''
      else
        correct_str = correctness.to_s.strip.empty? ? 'FALSE' : correctness.to_s.strip
        correct = ActiveModel::Type::Boolean.new.cast(correct_str)
        exp = explanation.to_s.strip
      end

      answer = Answer.new(
        type: answer_type_for_question(question_type),
        text: clean_text,
        correct: correct,
        explanation: exp
      )

      raise ProcessWorksheetError.new(answer.errors.full_messages.first) unless answer.valid?

      answer
    end

    def self.answer_type_for_question(question_type)
      return 'TextAnswer' if %w[MultipleChoice MultipleAnswer].include?(question_type)

      'FreeTextAnswer' if question_type == 'FreeText'
    end

    def self.clean_string(value)
      value.to_s.squish
    end
  end
end
