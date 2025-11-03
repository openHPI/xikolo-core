# frozen_string_literal: true

module TimeeffortService
class Operation # rubocop:disable Layout/IndentationWidth
  def initialize
    @errors = ActiveModel::Errors.new nil
  end

  attr_reader :errors

  def self.with_errors(errors)
    new.tap do |response|
      errors.each do |field, error|
        response.error! :base, "#{field}.#{error}"
      end
    end
  end

  def error!(key, msg)
    @errors.add key, msg
  end

  def success?
    @errors.empty?
  end
end
end
