# frozen_string_literal: true

class ValidateVideosPipStreamForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :videos, :streams, column: :pip_stream_id
  end
end
