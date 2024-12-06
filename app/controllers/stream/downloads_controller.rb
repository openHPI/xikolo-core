# frozen_string_literal: true

class Stream::DownloadsController < ApplicationController
  before_action :ensure_logged_in, unless: -> { browser.bot.search_engine? }

  def show
    redirect_to download_link
  rescue Video::Vimeo::API::RequestTimeout
    add_flash_message :error, t(:'flash.error.download_not_refreshed')
    redirect_back fallback_location: dashboard_url
  rescue Video::Download::QualityNotSupportedError, Video::Download::NoQualityAvailableError,
         Video::Download::VideoNotAvailableError
    add_flash_message :error, t(:'flash.error.download_not_available')
    redirect_back fallback_location: dashboard_url
  end

  private

  def stream_id
    UUID4.try_convert(params[:stream_id]).to_s
  end

  def download_link
    Video::Download.new(stream_id, params[:quality]).download_link
  end
end
