# frozen_string_literal: true

module QuizImporter
  class Scanner
    def initialize(rows)
      @rows = rows
    end

    def scan
      data = rows.map(&:dup)
      data.shift # remove header row

      quizzes = []
      current_quiz = nil

      data.each do |row|
        normalized = normalize_row(row)

        if normalized[0].present?
          # New quiz row
          current_quiz = QuizBuilder.build(normalized)
          quizzes << current_quiz
        else
          # Question row
          raise ProcessWorksheetError.new('Question found before any quiz') if current_quiz.nil?

          # First 4 columns are undefined; extract question fields starting at index 4
          question_fields = normalized.drop(4)
          question = QuestionBuilder.build(question_fields, current_quiz.type)
          current_quiz.add_question(question)

          # Remaining columns after the 5 question fields are answer triples
          answer_columns = question_fields.drop(5)
          answer_columns.each_slice(3) do |answer_text, correctness, explanation|
            next if answer_text.blank? # Skip if no answer text

            answer = AnswerBuilder.build(answer_text, correctness, explanation, question.type)
            question.add_answer(answer)
          end
        end
      end

      quizzes
    end

    private

    attr_accessor :rows

    def normalize_row(row)
      row.map {|v| v.nil? ? '' : v.to_s }
    end
  end
end
