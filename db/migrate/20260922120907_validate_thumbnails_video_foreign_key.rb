# frozen_string_literal: true

class ValidateThumbnailsVideoForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :thumbnails, :videos
  end
end
