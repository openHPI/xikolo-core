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

  def video_downloads
    [
      hd_video_button,
      sd_video_button,
      subtitled_stream_button,
      slides_button,
      transcript_button,
      reading_material_button,
      audio_button,
    ].compact.select {|download| download[:enabled] }
  end

  def player
    return Video::BunnyPlayer.build(video: @video, course: @course, user: @user) if Video::BunnyPlayer.compatible?(@video)
    return unless Video::VideoPlayer.compatible?(@video)

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
      title: I18n.t(:'items.show.video.download.hd_video'),
      url: download_path('hd'),
      file_type: 'mp4',
      enabled: downloads_enabled?,
    }
  end

  def sd_video_button
    return if pip_stream&.sd_download_url.blank?

    {
      title: I18n.t(:'items.show.video.download.sd_video'),
      url: download_path('sd'),
      file_type: 'mp4',
      enabled: downloads_enabled?,
    }
  end

  def subtitled_stream_button
    return if subtitled_stream&.sd_download_url.blank?

    {
      title: I18n.t(:'items.show.video.download.subtitled_video'),
      url: subtitled_stream.sd_download_url,
      file_type: 'mp4',
      enabled: downloads_enabled?,
    }
  end

  def slides_button
    return if @video.slides_url.blank?

    {
      title: I18n.t(:'items.show.video.download.slides'),
      url: @video.slides_url,
      file_type: file_extension(@video.slides_url),
      enabled: true,
    }
  end

  def transcript_button
    return if @video.transcript_url.blank?

    {
      title: I18n.t(:'items.show.video.download.transcript'),
      url: @video.transcript_url,
      file_type: file_extension(@video.transcript_url),
      enabled: true,
    }
  end

  def reading_material_button
    return if @video.reading_material_url.blank?

    {
      title: I18n.t(:'items.show.video.download.reading_material'),
      url: @video.reading_material_url,
      file_type: file_extension(@video.reading_material_url),
      enabled: true,
    }
  end

  def audio_button
    return if @video.audio_url.blank?

    {
      title: I18n.t(:'items.show.video.download.audio'),
      url: @video.audio_url,
      file_type: 'mp3',
      enabled: downloads_enabled?,
    }
  end

  def downloads_enabled?
    @course&.enable_video_download
  end

  def file_extension(url)
    File.extname(url).delete_prefix('.').presence
  end
end
