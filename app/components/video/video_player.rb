# frozen_string_literal: true

module Video
  class VideoPlayer < ApplicationComponent
    def self.compatible?(video)
      provider_types = %w[vimeo kaltura]

      [video.lecturer_stream, video.slides_stream, video.pip_stream, video.subtitled_stream].compact.all? do |stream|
        provider_types.include? stream.provider.provider_type
      end
    end

    def self.build(video:, user:, **opts)
      new(video, user:, opts:)
    end

    def initialize(video, user:, opts: {})
      @video = video
      @user = user
      @opts = opts
    end

    private

    def streams
      if @video.lecturer_stream && @video.slides_stream
        [
          render_stream(@video.lecturer_stream, 'primary'),
          render_stream(@video.slides_stream, 'secondary'),
          tag.xm_presentation('', reference: 'primary,secondary', name: 'dual',
            label: t(:'video_player.dual_stream_mode')),
        ]
      elsif @video.pip_stream
        [
          render_stream(@video.pip_stream, 'primary'),
          tag.xm_presentation('', reference: 'primary', name: 'single', label: t(:'video_player.single_stream_mode')),
        ]
      else
        # Invalid video configuration, do not render anything.
        []
      end
    end

    def render_stream(stream, name)
      return if stream.blank?

      case stream.provider.provider_type
        when 'vimeo'
          tag.xm_vimeo('', name:, src: stream.provider_video_id)
        when 'kaltura'
          tag.xm_kaltura('',
            name:,
            'partner-id': stream.provider.safe_metadata['partner_id'],
            'entry-id': stream.provider_video_id,
            duration: stream.duration,
            ratio: stream.height / stream.width.to_f,
            poster: stream.poster)
        else
          raise ArgumentError.new "Unknown video provider type #{provider.provider_type}"
      end
    end

    Subtitle = Struct.new(:url, :label, :default)
    private_constant :Subtitle

    def text_tracks
      return {} if @video.subtitles.blank?

      # :default is set nil to avoid rendering the default attribute
      # for a text track at all, where not applicable
      subs = @video.subtitles.map do |sub|
        [
          sub.lang,
          Subtitle.new(
            subtitle_path(sub.id),
            subtitle_label(sub),
            (sub.lang == user_preferences[:track_language]) || nil
          ),
        ]
      end

      # sort subtitles by language name (label)
      # and add position value
      subs
        .sort_by {|_, sub| sub.label }
        .each_with_index {|sub, i| sub.unshift i }
    end

    def thumbnails
      return unless @user.feature?('video_slide_thumbnails')
      return unless @opts.fetch(:load_thumbnails, false)

      # Map thumbnails to JSON structure that can be processed by the
      # video player. In case there are no thumbnails, `nil` must be
      # returned instead of `"[]"`.
      @video.thumbnails.map(&:as_json).presence&.to_json
    end

    def subtitle_label(subtitle)
      if subtitle.automatic
        I18n.t(:'subtitles.machine_translated', language: I18n.t(:"subtitles.languages.#{subtitle.lang}"))
      else
        I18n.t(:"subtitles.languages.#{subtitle.lang}")
      end
    end

    def transcript
      @video.subtitles.present?
    end

    def toggle_button_default_state
      prefs['ui.video.video_player_show_transcript'].to_s == 'true'
    end

    def hide_transcript_by_default
      !toggle_button_default_state || @video.subtitles.blank?
    end

    def user_preferences
      {
        playback_rate: preferred_playback_rate,
        track_language: prefs['ui.video.video_player_caption_language'],
        show_subtitle: prefs['ui.video.video_player_show_captions'].to_s == 'true',
      }.compact
    end

    ALLOWED_PLAYBACK_RATES = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].freeze
    private_constant :ALLOWED_PLAYBACK_RATES
    # Try to match the player speed from the user's legacy preferences.
    # Returns nil if the value is not supported by the video player.
    def preferred_playback_rate
      ALLOWED_PLAYBACK_RATES.detect do |rate|
        prefs['ui.video.video_player_speed']&.to_f == rate
      end
    end

    def prefs
      @prefs ||= @user.preferences.value!
    end
  end
end
