# frozen_string_literal: true

class UploadVideoToBunnyJob < ApplicationJob
  queue_as :default

  retry_on Video::Bunny::Error, wait: :polynomially_longer, attempts: 5

  def perform(short_id)
    short = CourseService::Short.find(short_id)

    return if short.video.blank?

    library_id = ENV.fetch('BUNNY_VIDEO_LIBRARY_ID')

    # Persist the provider video id immediately after creating the video on
    # Bunny, so a failed or retried upload re-uses the existing video instead
    # of creating a duplicate.
    if short.bunny_video_id.nil?
      video_id = CreateVideoOnBunny.new(
        library_id: library_id,
        title: short.title
      ).call
      short.update!(bunny_video_id: video_id)
    else
      video_id = short.bunny_video_id
    end

    UploadVideoOnBunny.new(
      library_id: library_id,
      video_id: video_id,
      video_attachment: short.video
    ).call
  end
end
