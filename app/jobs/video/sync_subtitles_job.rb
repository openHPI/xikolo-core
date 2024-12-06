# frozen_string_literal: true

module Video
  class SyncSubtitlesJob < ApplicationJob
    def perform(video_id, language)
      video = ::Video::Video.find(video_id)
      stream = video.pip_stream || video.lecturer_stream || video.slides_stream

      stream.provider.remove_subtitles!(stream, language)

      if (subtitle = video.subtitles.find_by(lang: language))
        stream.provider.attach_subtitles! stream, subtitle
      end
    rescue ActiveRecord::RecordNotFound
      # noop
    end
  end
end
