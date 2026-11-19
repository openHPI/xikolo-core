# frozen_string_literal: true

class UploadStreamToBunnyJob < ApplicationJob
  queue_as :default

  retry_on Video::Bunny::Error, wait: :polynomially_longer, attempts: 5

  def perform(stream_id)
    stream = Video::Stream.find(stream_id)

    return if stream.video.blank?

    library_id = ENV.fetch('BUNNY_VIDEO_LIBRARY_ID')

    stream.mark_uploading!

    # The stream is saved before it exists on Bunny. Create it there if needed
    # and persist the provider id immediately, so a later failure (or a retry)
    # re-uploads the same video instead of creating a duplicate.
    if stream.provider_video_id.blank?
      guid = CreateVideoOnBunny.new(library_id: library_id, title: stream.title).call
      stream.update!(
        provider_video_id: guid,
        hls_url: bunny_url(guid, 'playlist.m3u8'),
        poster: bunny_url(guid, 'thumbnail.jpg')
      )
    end

    UploadVideoOnBunny.new(
      library_id: library_id,
      video_id: stream.provider_video_id,
      video_attachment: stream.video
    ).call

    stream.mark_upload_ready!
  rescue Video::Bunny::Error => e
    stream.mark_upload_failed!(e)
    raise
  end

  private

  def bunny_url(guid, path)
    cdn_host = ENV.fetch('BUNNY_VIDEO_CDN_HOST', 'video.bunnycdn.com')
    "https://#{cdn_host}/#{guid}/#{path}"
  end
end
