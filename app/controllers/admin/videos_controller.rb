# frozen_string_literal: true

class Admin::VideosController < Abstract::FrontendController
  def index
    authorize! 'video.video.manage'

    streams = Video::Stream.includes(:provider).query(params[:prefix])
    @streams = streams.paginate(page: params[:page] || 1, per_page: 50)
  end

  def destroy
    authorize! 'video.video.manage'

    stream = Video::Stream.find(params[:id])
    if stream.destroy
      add_flash_message :success, t(:'flash.success.video_stream_deleted')
    else
      add_flash_message :error, t(:'flash.error.video_stream_not_deleted')
    end

    redirect_to videos_path, status: :see_other
  rescue ActiveRecord::DeleteRestrictionError
    add_flash_message :error, t(:'flash.error.video_stream_not_deleted')
    redirect_to videos_path, status: :see_other
  end
end
