# frozen_string_literal: true

class Admin::VideosController < Abstract::FrontendController
  def index
    authorize! 'video.video.manage'

    streams = Video::Stream.includes(:provider).query(params[:prefix])
    @streams = streams.paginate(page: params[:page] || 1, per_page: 50)
  end

  def new
    authorize! 'video.video.manage'

    @stream = Video::Stream.new
  end

  def create
    authorize! 'video.video.manage'

    provider = Video::Provider.bunny!

    video_param = video_stream_params[:video]
    if video_param.blank?
      @stream = Video::Stream.new(title: video_stream_params[:title])
      add_flash_message :error, t(:'flash.error.video_stream_no_file')
      return render :new, status: :unprocessable_content
    end

    blob = video_param.is_a?(String) ? ActiveStorage::Blob.find_signed!(video_param) : video_param

    stream = provider.streams.new(title: video_stream_params[:title].presence || blob&.filename)
    stream.video = video_param

    if stream.save
      stream.start_upload!
      UploadStreamToBunnyJob.perform_later(stream.id)
      add_flash_message :success, t(:'flash.success.video_stream_created')
      redirect_to videos_path, status: :see_other
    else
      stream.video.purge_later if stream.video.attached?
      @stream = stream
      add_flash_message :error, t(:'flash.error.video_stream_not_created')
      render :new, status: :unprocessable_content
    end
  end

  def retry
    authorize! 'video.video.manage'

    stream = Video::Stream.find(params[:id])
    if stream.failed?
      stream.retry_upload!
      add_flash_message :success, t(:'flash.success.video_stream_retry_enqueued')
    else
      add_flash_message :error, t(:'flash.error.video_stream_not_retryable')
    end

    redirect_to videos_path, status: :see_other
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

  private

  def video_stream_params
    params.require(:video_stream).permit(:title, :video)
  end
end
