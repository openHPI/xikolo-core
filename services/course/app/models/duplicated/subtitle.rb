# frozen_string_literal: true

module Duplicated
  class Subtitle < ::ApplicationRecord
    belongs_to :video, class_name: '::Duplicated::Video'
    has_many :cues, class_name: '::Duplicated::SubtitleCue', dependent: :destroy

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
