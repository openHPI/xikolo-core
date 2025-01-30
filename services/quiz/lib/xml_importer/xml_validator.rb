# frozen_string_literal: true

module XMLImporter
  ##
  # Handle general XML validation logic:
  # Validate the quiz XML against a predefined schema.
  class XMLValidator
    QUIZ_XML_SCHEMA_FILE = 'app/assets/quiz_import_schema.xml'

    def initialize(xml_string)
      @schema = Nokogiri::XML::Schema(File.read(QUIZ_XML_SCHEMA_FILE))
      @xml_string = xml_string
    end

    def validate!
      errors = @schema.validate(Nokogiri::XML(@xml_string))
      raise ::XMLImporter::SchemaError.new(errors.collect(&:message)) if errors.any?
    end
  end
end
