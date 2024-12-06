# frozen_string_literal: true

class VideoPresenter
  def initialize(video:, user:, embed_resources: false, course: nil)
    @video = video
    @user = user
    @embed_resources = embed_resources
    @course = course
  end

  def description
    @video.description&.external
  end

  def pip_stream
    @video.pip_stream
  end

  def lecturer_stream
    @video.lecturer_stream
  end

  def slides_stream
    @video.slides_stream
  end

  def subtitled_stream
    @video.subtitled_stream
  end

  def thumbnail
    @video.thumbnail
  end

  def video_download_dropdowns
    [
      {
        text: I18n.t(:'items.show.video.video_downloads'),
        buttons: [
          hd_video_button,
          sd_video_button,
        ].compact,
      },
      {
        text: I18n.t(:'items.show.video.additional_downloads'),
        buttons: [
          subtitled_stream_button,
          slides_button,
          transcript_button,
          reading_material_button,
          audio_button,
        ].compact,
      },
    ]
  end

  def player
    return unless Video::VideoPlayer.compatible? @video

    @player ||= Video::VideoPlayer.build(
      video: @video,
      user: @user,
      load_thumbnails: @embed_resources
    )
  end

  private

  def download_path(quality)
    Rails.application.routes.url_helpers
      .stream_download_path(UUID4(pip_stream.id).to_param, quality)
  end

  def hd_video_button
    return if pip_stream&.hd_download_url.blank?

    {
      path: download_path('hd'),
      caption: I18n.t(:'items.show.video.download.hd_video'),
      verb: 'downloaded_hd_video',
      enabled: @course.enable_video_download,
    }
  end

  def sd_video_button
    return if pip_stream&.sd_download_url.blank?

    {
      path: download_path('sd'),
      caption: I18n.t(:'items.show.video.download.sd_video'),
      verb: 'downloaded_sd_video',
      enabled: @course.enable_video_download,
    }
  end

  def subtitled_stream_button
    return if subtitled_stream&.sd_download_url.blank?

    {
      path: subtitled_stream.sd_download_url,
      caption: I18n.t(:'items.show.video.download.subtitled_video'),
      verb: 'downloaded_subtitled_video',
      enabled: @course.enable_video_download,
    }
  end

  def slides_button
    return if @video.slides_url.blank?

    {
      path: @video.slides_url,
      caption: I18n.t(:'items.show.video.download.slides'),
      verb: 'downloaded_slides',
      enabled: true,
    }
  end

  def transcript_button
    return if @video.transcript_url.blank?

    {
      path: @video.transcript_url,
      caption: I18n.t(:'items.show.video.download.transcript'),
      verb: 'downloaded_transcript',
      enabled: true,
    }
  end

  def reading_material_button
    return if @video.reading_material_url.blank?

    {
      path: @video.reading_material_url,
      caption: I18n.t(:'items.show.video.download.reading_material'),
      verb: 'downloaded_reading_material',
      enabled: true,
    }
  end

  def audio_button
    return if @video.audio_url.blank?

    {
      path: @video.audio_url,
      caption: I18n.t(:'items.show.video.download.audio'),
      verb: 'downloaded_audio',
      enabled: @course.enable_video_download,
    }
  end
end
