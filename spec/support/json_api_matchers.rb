# frozen_string_literal: true

require 'rspec/expectations'

def match_json_api_data(&)
  match do |actual|
    actual = actual['data']

    if actual.is_a? Array
      actual.all?(&)
    else
      yield actual
    end
  end
end

RSpec::Matchers.define :have_type do |expected|
  match_json_api_data do |actual|
    actual.is_a?(Hash) && actual['type'] == expected
  end
  failure_message do |actual|
    "expected that #{actual} would have the type #{expected}"
  end
end

RSpec::Matchers.define :have_id do |expected|
  match_json_api_data do |actual|
    actual.is_a?(Hash) && actual['id'] == expected
  end
  failure_message do |actual|
    "expected that #{actual} would have the ID #{expected}"
  end
end

RSpec::Matchers.define :have_attribute do |expected|
  match_json_api_data do |actual|
    actual['attributes'].key? expected
  end
  failure_message do |actual|
    "expected that #{actual} would contain a #{expected} attribute"
  end
end
