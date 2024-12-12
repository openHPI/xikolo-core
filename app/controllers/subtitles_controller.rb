# frozen_string_literal: true

class SubtitlesController < ApplicationController
  def show
    # Required CORS header to support Google Cast and other web-based video
    # players. Since we do not know exactly which domains from Google access
    # the streams, we use a wildcard.
    response.headers['Access-Control-Allow-Origin'] = '*'

    subtitle = Video::Subtitle.find(params[:id])

    render plain: subtitle.to_vtt, content_type: 'text/vtt'
  rescue ActiveRecord::RecordNotFound
    head(:not_found, content_type: 'text/plain')
  end

  def destroy
    authorize! 'video.subtitle.manage'

    Video::Subtitle.find(params[:id]).destroy

    redirect_back fallback_location: root_path
  rescue ActiveRecord::RecordNotFound
    head(:not_found, content_type: 'text/plain')
  end
end
