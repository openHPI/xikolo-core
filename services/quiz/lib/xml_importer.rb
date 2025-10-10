# frozen_string_literal: true

module XmlImporter
  require 'xml_importer/course'
  require 'xml_importer/quiz'
  require 'xml_importer/quiz_persistence'
  require 'xml_importer/quiz_validator'
  require 'xml_importer/xml_validator'

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
