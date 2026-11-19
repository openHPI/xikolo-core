# frozen_string_literal: true

module QuizImporter
  class LoadWorksheetError < StandardError;; end
  class ProcessWorksheetError < StandardError;; end

  def self.import(spreadsheet:, worksheet:, course_code:)
    rows    = Loader.new(spreadsheet: spreadsheet, worksheet: worksheet).load
    quizzes = Scanner.new(rows).scan
    Persister.new(CourseService::Course.find_by!(course_code: course_code), quizzes).persist!
  end
end
