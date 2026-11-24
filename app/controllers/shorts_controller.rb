# frozen_string_literal: true

class ShortsController < Abstract::AjaxController
  def signed_url
    short_id = params[:id]

    if Rails.env.development? && short_id.in?(Shorts::DemoMedia.ids)
      redirect_to Shorts::DemoMedia.video_url(short_id), allow_other_host: true
      return
    end

    short = CourseService::Short.active.find(params[:id])
    signed = BunnySignedURL.new.call(short.bunny_video_id)

    redirect_to signed.fetch(:video), allow_other_host: true
  end
end
