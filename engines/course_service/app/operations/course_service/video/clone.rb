# frozen_string_literal: true

require 'xikolo/s3'

module CourseService
class Video::Clone < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  def initialize(original_video)
    super()

    @original_video = original_video
  end

  def call
    Duplicated::Video.transaction do
      @video = Duplicated::Video.new(
        @original_video.attributes.except(
          'id', 'slides_uri', 'transcript_uri', 'reading_material_uri', 'thumbnails_uri'
        ).merge(id: SecureRandom.uuid)
      )

      # Clone file attachments
      @video.assign_attributes(
        slides_uri: copy_file(@original_video.slides_uri),
        transcript_uri: copy_file(@original_video.transcript_uri),
        reading_material_uri: copy_file(@original_video.reading_material_uri)
      )

      if @video.save
        clone_subtitles!
      end
    end

    @video
  end

  private

  def clone_subtitles!
    return if @original_video.subtitles.blank?

    @original_video.subtitles.each do |subtitle|
      subtitle.clone video_id: @video.id
    end
  end

  def copy_file(uri)
    return unless uri

    original = Xikolo::S3.object(uri)
    # Replace video ID in key
    key = original.key.split('/').tap do |parts|
      parts[1] = UUID4(@video.id).to_s(format: :base62)
    end.join('/')

    Xikolo::S3.copy_to(original, target: key, bucket: :video, acl: 'public-read',
      content_disposition: original.content_disposition)
  end
end
end
