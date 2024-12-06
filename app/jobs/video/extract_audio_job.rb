# frozen_string_literal: true

require 'streamio-ffmpeg'

module Video
  class ExtractAudioJob < ApplicationJob
    queue_as :default

    def perform(stream_id)
      return unless Xikolo.config.video['audio_extraction']

      stream = ::Video::Stream.find stream_id
      old_audio_uri = stream.audio_uri if stream.audio_uri?

      # Download the file and extract its audio content
      FFMPEG::Movie.new(stream.sd_url).transcode(
        mp3_file.path,
        audio_codec: 'libmp3lame',
        custom: %w[-qscale:a 6 -ac 1]
      )

      # Store reference:
      object = upload_file(File.open(mp3_file), stream)

      stream.audio_uri = object.storage_uri
      stream.save!

      # Remove old file:
      S3FileDeletionJob.perform_later(old_audio_uri) if old_audio_uri
    end

    private

    def mp3_file
      @mp3_file ||= Tempfile.new %w[audio .mp3]
    end

    def upload_file(io, stream)
      upload = Xikolo::S3::SingleFileUpload.new(stream.id)

      return if upload.empty?

      upload_object = upload.accepted_file!
      s_id = UUID4(stream.id).to_str(format: :base62)

      # Upload audio:
      Xikolo::S3.bucket_for(:video).put_object(
        key: "streams/#{s_id}/audio/#{upload_object.unique_sanitized_name}",
        body: io,
        acl: 'public-read',
        content_type: 'audio/mp3',
        cache_control: 'public, max-age=7776000',
        content_disposition: "attachment; filename=\"#{upload_object.sanitized_name}\""
      )
    end
  end
end
