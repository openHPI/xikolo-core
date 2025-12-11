# frozen_string_literal: true

require 'quiz_service/points_processor'
require 'quiz_service/xml_importer/course'
require 'quiz_service/xml_importer/quiz'
require 'quiz_service/xml_importer/quiz_persistence'
require 'quiz_service/xml_importer/quiz_validator'
require 'quiz_service/xml_importer/xml_validator'

module QuizService
module XmlImporter # rubocop:disable Layout/IndentationWidth
  class SchemaError < StandardError
    attr_reader :errors

    def initialize(errors)
      errors = Array(errors)
      super("There are schema errors: #{errors.join(', ')}")
      @errors = errors
    end
  end

  class ParameterError < StandardError
    attr_reader :errors

    def initialize(errors)
      errors = Array(errors)
      super("There are parameter errors: #{errors.join(', ')}")
      @errors = errors
    end
  end
end
end
