# frozen_string_literal: true

require 'zip'
require 'webvtt'

module Video
  class Subtitle < ::ApplicationRecord
    belongs_to :video, class_name: '::Video::Video'
    has_many :cues, class_name: '::Video::SubtitleCue', dependent: :destroy

    after_commit(on: %i[create update]) do
      ::Video::SyncSubtitlesJob.perform_later(video_id, lang) if trigger_subtitle_sync?
    end
    after_commit(on: :destroy) { ::Video::SyncSubtitlesJob.perform_later(video_id, lang) }

    validates :lang, presence: true, uniqueness: {scope: :video_id}

    class << self
      # Extract the in S3 stored zip file
      # And attach the contained subtitles to the given video
      # The S3 object remains unchanged!
      def extract!(object, video)
        Zip::File.open_buffer(object.get.body) do |zipfile|
          zipfile.each do |entry|
            lang = extract_lang(entry.name)
            next unless lang

            attach!(entry.get_input_stream.read, lang, video, automatic: false)
          end
        end
      end

      def attach!(src_vtt, lang, video, automatic:)
        Subtitle.transaction do
          subtitle = video.subtitles.find_or_create_by!(lang:)

          # Delete subtitle and its cues if no cues are provided.
          if src_vtt.blank?
            subtitle.destroy
            next # Commit the transaction since the subtitle should be deleted.
          end

          # Update the subtitle cues from the VTT file.
          subtitle.update(automatic:)
          subtitle.create_cues! src_vtt

          # Trigger the subtitle sync for both update and create.
          subtitle.trigger_subtitle_sync!
        end
      end

      def extract_lang(name)
        return false if name.start_with?('__MACOSX')
        return Regexp.last_match(1).downcase if name =~ /[-_]([a-z]{2,3})\.vtt$/i

        false
      end
    end

    def create_cues!(src_vtt)
      return if src_vtt.blank?

      # Destroy cues so they can be re-created (and updated) correctly
      cues.destroy_all

      webvtt = WebVTT.from_blob sanitize_vtt(src_vtt.dup)

      SubtitleCue.transaction do
        identifiers_for_cues_with_errors = []

        webvtt.cues.each_with_index do |cue, i|
          # Cue identifiers are optional, as described in the Mozilla description for the WebVTT cues
          # https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API#webvtt_cues
          identifier = cue.identifier || (i + 1)

          cues.create!(
            identifier:,
            start: cue.start.to_f,
            stop: cue.end.to_f,
            text: cue.text,
            style: cue.style
          )
        rescue ActiveRecord::RecordInvalid
          identifiers_for_cues_with_errors << identifier
          next
        end

        if identifiers_for_cues_with_errors.any?
          raise InvalidSubtitleError.new 'invalid_subtitle', identifiers_for_cues_with_errors
        end
      end
    end

    def trigger_subtitle_sync?
      @trigger_subtitle_sync
    end

    def trigger_subtitle_sync!
      @trigger_subtitle_sync = true
    end

    def as_api_v2
      @api_v2 ||= ::Video::SubtitleTrack::APIV2.new(self).as_json # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def to_vtt
      "WEBVTT\n\n#{cues.map(&:to_vtt).join("\n")}"
    end

    private

    def sanitize_vtt(src_vtt)
      # Remove spaces before line breaks
      src_vtt.gsub(/ *(?=\r\n|\r|\n)/, '').force_encoding('UTF-8')
    end
  end

  class InvalidSubtitleError < StandardError
    attr_reader :identifiers

    def initialize(message, identifiers)
      @identifiers = identifiers
      super(message)
    end
  end
end
