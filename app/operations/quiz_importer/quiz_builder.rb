# frozen_string_literal: true

module QuizImporter
  class QuizBuilder
    QUIZ_TYPES = {
      'selftest' => {attempts: 0, time: 0, graded: false, bonus: false, survey: false, final_exam: false},
      'weekly assignment' => {attempts: 1, time: 3600, graded: true, bonus: false, survey: false, final_exam: false},
      'bonus' => {attempts: 1, time: 3600, graded: true, bonus: true, survey: false, final_exam: false},
      'final exam' => {attempts: 2, time: 3600, graded: true, bonus: false, survey: false, final_exam: true},
      'survey' => {attempts: 1, time: 0, graded: false, bonus: false, survey: true, final_exam: false},
    }.freeze

    def self.build(row)
      name = clean_string(row[0])
      quiz_type = clean_string(row[2])
      flags = QUIZ_TYPES[quiz_type]

      section_str = clean_string(row[1])
      section, subsection = parse_section(section_str)

      quiz = Quiz.new(
        name: name,
        section: section,
        subsection: subsection,
        type: quiz_type,
        instructions: row[3].to_s.strip,
        **flags
      )

      raise ProcessWorksheetError.new(quiz.errors.full_messages.first) unless quiz.valid?

      quiz
    end

    def self.parse_section(value)
      parts = value.split('.')
      section = Integer(parts[0].to_s.strip)
      subsection = Integer(parts[1].to_s.strip) if parts[1] && !parts[1].strip.empty?
      raise ArgumentError if section.negative? || subsection&.negative?

      [section, subsection]
    rescue StandardError
      raise ProcessWorksheetError.new(%(Wrong format for quiz section "#{value}" (must be non-negative integer or X.Y)))
    end

    def self.clean_string(value)
      value.to_s.squish
    end
  end
end
