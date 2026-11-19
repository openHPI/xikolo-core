# frozen_string_literal: true

module Video
  class BunnyPlayer < ApplicationComponent
    # Only a video with a single ready Bunny stream is supported for now.
    def self.compatible?(video)
      video.display_streams.one? && video.bunny_stream.present? && video.bunny_stream.ready?
    end

    def self.build(video:, course:, **)
      new(video, course:, **)
    end

    def initialize(video, course:, signed_url_path: nil, poster: nil, user: nil)
      @video = video
      @course = course
      @signed_url_path = signed_url_path
      @poster = poster
      @user = user
    end

    private

    def stream
      @video.bunny_stream
    end

    def poster
      @poster.presence || stream.poster_url
    end

    def video_options
      options = {
        class: 'block h-full w-full',
        src: signed_url_path,
        playsinline: true,
        crossorigin: 'anonymous',
      }
      # Only skip preloading when a poster covers the idle state; otherwise
      # the user would see a black box until playback starts.
      options[:preload] = 'none' if poster.present?
      options[:poster] = poster if poster.present?
      options
    end

    def aspect_ratio
      stream.width.to_i.positive? && stream.height.to_i.positive? ? stream.width.to_f / stream.height : 16.0 / 9
    end

    def signed_url_path
      return @signed_url_path if @signed_url_path

      signed_url_course_item_path(course_id: @course.course_code, id: UUID(@video.item.id).to_param)
    end

    def subtitle_label(subtitle)
      language = t(:"subtitles.languages.#{subtitle.lang}")
      subtitle.automatic ? t(:'subtitles.machine_translated', language:) : language
    end

    def default_track_language
      return if @user.nil?
      return unless captions_enabled?

      @user.preferences['ui.video.video_player_caption_language']
    end

    def captions_enabled?
      @user.preferences['ui.video.video_player_show_captions'].to_s == 'true'
    end
  end
end
