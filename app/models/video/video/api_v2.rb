# frozen_string_literal: true

module Video
  class Video
    class APIV2
      def initialize(video)
        @video = video
      end

      def as_json(opts = {})
        {
          id: @video.id,
          description: @video.description&.external,
          duration: @video.duration,
          pip_stream_id: @video.pip_stream_id,
          lecturer_stream_id: @video.lecturer_stream_id,
          slides_stream_id: @video.slides_stream_id,
          slides_url: download_material[:slides_url],
          slides_size: download_material[:slides_size],
          audio_url: download_material[:audio_url],
          audio_size: download_material[:audio_size],
          transcript_url: download_material[:transcript_url],
          transcript_size: download_material[:transcript_size],
          thumbnail: @video.thumbnail,
          subtitles:,
        }.as_json(opts)
      end

      private

      # Construct a hash for the download material as follows:
      # {
      #   audio_url: 'https://s3.xikolo.de/audio.url/',
      #   audio_size: 1234,
      # }
      def download_material
        @download_material ||= %w[audio slides transcript]
          .map {|type| [type, @video.send(:"#{type}_url")] }
          .select {|ary| ary[1].present? }
          # Load video and all related stream information, as parallel as possible
          .map {|(type, url)| [type, Restify.new(url).head] }
          .map {|(type, req)| [type, req.value] }
          .flat_map do |(type, req)|
            # Extract the file sizes from the responses if the corresponding
            # file could be loaded. Otherwise, skip (add empty array to be
            # able to convert to hash later on).
            next [] unless req

            [
              [:"#{type}_url", @video.send(:"#{type}_url")],
              [:"#{type}_size", req.response.headers['CONTENT_LENGTH']],
            ]
          end.to_h
      end

      def subtitles
        @video.subtitles.map do |subtitle|
          {
            language: subtitle.lang,
            created_by_machine: subtitle.automatic,
            vtt_url: Xikolo::V2::URL.subtitle_url(subtitle.id),
          }
        end
      end
    end
  end
end
