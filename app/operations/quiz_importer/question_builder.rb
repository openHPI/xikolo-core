# frozen_string_literal: true

module QuizImporter
  class QuestionBuilder
    QUESTION_TYPE_MAP = {
      'MultipleChoice' => 'MultipleChoice',
      'SingleSelect' => 'MultipleChoice',
      'MultipleAnswer' => 'MultipleAnswer',
      'MultiSelect' => 'MultipleAnswer',
      'FreeText' => 'FreeText',
    }.freeze

    def self.build(row, quiz_type)
      text = clean_string(row[0])

      raw_type = clean_string(row[1])
      q_type = QUESTION_TYPE_MAP[raw_type]

      points = row[2].to_s.strip
      explanation = row[3].to_s.strip
      exclude_val = row[4]
      exclude_val = 'FALSE' if exclude_val.nil? || exclude_val.to_s.strip.empty?

      shuffle = quiz_type != 'survey'

      question = Question.new(
        text: text,
        type: q_type,
        points: points,
        explanation: explanation,
        exclude_from_recap: exclude_val,
        shuffle_answers: shuffle
      )

      raise ProcessWorksheetError.new(question.errors.full_messages.first) unless question.valid?

      question
    end

    def self.clean_string(value)
      value.to_s.squish
    end
  end
end
