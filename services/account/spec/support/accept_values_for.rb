# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :accept_values_for do |field, *values|
  match do |actual|
    values.all? do |value|
      old = actual.send(field)

      begin
        actual.send(:"#{field}=", value)
        actual.valid?
      ensure
        actual.send(:"#{field}=", old)
      end
    end
  end

  match_when_negated do |actual|
    values.all? do |value|
      old = actual.send(field)

      begin
        actual.send(:"#{field}=", value)
        actual.invalid?
      ensure
        actual.send(:"#{field}=", old)
      end
    end
  end
end
