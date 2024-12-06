# frozen_string_literal: true

# Development seeds for miscellaneous extras.

WellKnownFile.find_or_create_by(filename: 'security.txt') do |file|
  file.content = <<~CONTENT
    Contact: mailto:info@company.de
    Expires: 6666-01-01T00:00:00.000Z
  CONTENT
end
