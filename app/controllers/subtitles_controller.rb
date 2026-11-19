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

  def download
    authorize! 'video.subtitle.manage'

    subtitle = Video::Subtitle.find(params[:id])

    send_data(
      subtitle.to_vtt,
      type: 'text/vtt',
      filename: subtitle.download_filename,
      disposition: 'attachment'
    )
  end

  def destroy
    authorize! 'video.subtitle.manage'

    Video::Subtitle.find(params[:id]).destroy

    redirect_back_or_to(root_path)
  rescue ActiveRecord::RecordNotFound
    head(:not_found, content_type: 'text/plain')
  end
end
