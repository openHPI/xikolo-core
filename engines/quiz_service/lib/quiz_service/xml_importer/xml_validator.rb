# frozen_string_literal: true

module QuizService
module XmlImporter # rubocop:disable Layout/IndentationWidth
  ##
  # Handle general XML validation logic:
  # Validate the quiz XML against a predefined schema.
  class XmlValidator
    QUIZ_XML_SCHEMA_FILE = 'engines/quiz_service/app/assets/quiz_import_schema.xml'

    def initialize(xml_string)
      @schema = Nokogiri::XML::Schema(File.read(QUIZ_XML_SCHEMA_FILE))
      @xml_string = xml_string
    end

    def validate!
      errors = @schema.validate(Nokogiri::XML(@xml_string))
      raise XmlImporter::SchemaError.new(errors.collect(&:message)) if errors.any?
    end
  end
end
end
