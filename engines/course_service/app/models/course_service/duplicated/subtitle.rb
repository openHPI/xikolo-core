# frozen_string_literal: true

module CourseService
module Duplicated # rubocop:disable Layout/IndentationWidth
  class Subtitle < ApplicationRecord
    self.table_name = :subtitles

    belongs_to :video, class_name: 'CourseService::Duplicated::Video'
    has_many :cues, class_name: 'CourseService::Duplicated::SubtitleCue', dependent: :destroy

    validates :lang, presence: true, uniqueness: {scope: :video_id}

    def clone(attrs = {})
      self.class.create(
        attributes.except('id').merge(attrs)
      ).tap do |subtitle|
        cues.each do |cue|
          cue.clone(subtitle_id: subtitle.id)
        end
      end
    end
  end
end
end
