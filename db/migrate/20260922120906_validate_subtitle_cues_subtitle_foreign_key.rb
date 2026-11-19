# frozen_string_literal: true

class ValidateSubtitleCuesSubtitleForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :subtitle_cues, :subtitles
  end
end
