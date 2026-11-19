# frozen_string_literal: true

module Maintenance
  # Downloads the video files of all Vimeo streams and stores them as Active
  # Storage attachments.
  #
  # The task is idempotent: only streams that do not have a video attached yet
  # are processed, so it can be safely re-run or resumed after being paused.
  class AttachVimeoVideosTask < MaintenanceTasks::Task
    def collection
      # The default scope orders by `created_at`, but the job-iteration cursor
      # requires an un-ordered relation (it keyset-pages by the primary key).
      Video::Stream.where.missing(:video_attachment).reorder(nil)
    end

    def process(stream)
      url = stream_download_url(stream)
      return if url.blank?

      file = Tempfile.new %w[video .mp4]
      file.binmode
      begin
        download(file, url)
        file.rewind
        stream.video.attach(
          io: file,
          filename: "#{stream.provider_video_id}.mp4",
          content_type: 'video/mp4'
        )
      ensure
        file.close!
      end
    rescue Video::Download::VideoNotAvailableError => e
      Rails.logger.warn(
        "Skipping stream #{stream.id} (provider video #{stream.provider_video_id}): " \
        "download video not available: #{e.message}"
      )
    end

    private

    def stream_download_url(stream)
      downloads = stream.current_downloads

      downloads.fetch(:hd)
    end

    def download(file, url)
      connection = Faraday.new do |faraday|
        faraday.response :follow_redirects
        faraday.adapter :net_http
      end

      response = connection.get(url) do |request|
        request.options.on_data = proc {|chunk, _size, _env| file.write(chunk) }
      end

      raise Faraday::Error("expected a successful response but got #{response.status}") \
        unless response.success?
    end
  end
end
