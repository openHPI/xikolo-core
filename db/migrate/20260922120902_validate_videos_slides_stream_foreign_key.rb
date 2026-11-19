# frozen_string_literal: true

class ValidateVideosSlidesStreamForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :videos, :streams, column: :slides_stream_id
  end
end
