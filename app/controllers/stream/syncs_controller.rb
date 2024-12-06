# frozen_string_literal: true

class Stream::SyncsController < ApplicationController
  before_action :ensure_logged_in

  def create
    authorize! 'video.video.index'

    Video::Stream.find(params[:stream_id]).sync

    add_flash_message(:success, t(:'flash.success.single_video_synced'))
    redirect_to videos_path
  rescue ActiveRecord::RecordNotFound, Kaltura::KalturaAPIError
    add_flash_message(:error, t(:'flash.error.single_video_sync_failed'))
    redirect_to videos_path
  end
end
