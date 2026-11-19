# frozen_string_literal: true

class ValidateVideosSubtitledStreamForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :videos, :streams, column: :subtitled_stream_id
  end
end
