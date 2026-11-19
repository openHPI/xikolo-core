# frozen_string_literal: true

class ValidateVideosLecturerStreamForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :videos, :streams, column: :lecturer_stream_id
  end
end
