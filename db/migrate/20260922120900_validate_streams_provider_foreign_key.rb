# frozen_string_literal: true

class ValidateStreamsProviderForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :streams, :providers
  end
end
