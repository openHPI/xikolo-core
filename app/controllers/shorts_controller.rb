# frozen_string_literal: true

class ShortsController < Abstract::AjaxController
  def signed_url
    short_id = params[:id]

    if Rails.env.development? && short_id.in?(Shorts::CarouselPreview.short_ids)
      redirect_to preview_shorts_urls(short_id), allow_other_host: true
      return
    end

    short = CourseService::Short.active.find(params[:id])
    signed = BunnySignedURL.new.call(short.bunny_video_id)

    redirect_to signed.fetch(:video), allow_other_host: true
  end

  private

  def preview_shorts_urls(short_id)
    "https://vz-690a2860-9e9.b-cdn.net/#{short_id}/playlist.m3u8"
  end
end
