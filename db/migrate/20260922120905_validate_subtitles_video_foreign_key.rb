# frozen_string_literal: true

class ValidateSubtitlesVideoForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :subtitles, :videos
  end
end
