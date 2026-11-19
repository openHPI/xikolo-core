# frozen_string_literal: true

# Adds the missing foreign keys for the video domain.
#
# All keys are added with `validate: false` on purpose: existing (and possibly
# duplicate or orphaned) production data is not scanned or validated here. The
# keys start enforcing referential integrity for new writes immediately.
# A follow-up migration should validate the keys once the data has been cleaned
# up (see `Maintenance::DeduplicateVideoStreamsTask`).
class AddForeignKeysToVideoModels < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :streams, :providers, validate: false
    add_foreign_key :videos, :streams, column: :lecturer_stream_id, validate: false
    add_foreign_key :videos, :streams, column: :slides_stream_id, validate: false
    add_foreign_key :videos, :streams, column: :pip_stream_id, validate: false
    add_foreign_key :videos, :streams, column: :subtitled_stream_id, validate: false
    add_foreign_key :subtitles, :videos, validate: false
    add_foreign_key :subtitle_cues, :subtitles, validate: false
    add_foreign_key :thumbnails, :videos, validate: false
    add_foreign_key :course_visuals, :videos, validate: false
  end
end
