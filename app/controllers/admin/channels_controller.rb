# frozen_string_literal: true

class Admin::ChannelsController < Abstract::FrontendController
  include ChannelHelper

  def index
    authorize! 'course.channel.index'

    @channels = Course::Channel.not_deleted.where(affiliated: false).ordered
  end

  def new
    authorize! 'course.channel.create'
    @channel = Admin::ChannelEditPresenter.new
  end

  def edit
    authorize! 'course.channel.edit'
    channel = course_api.rel(:channel).get({id: params[:id]}).value!
    @channel = Admin::ChannelEditPresenter.new channel:
  end

  def create
    authorize! 'course.channel.create'

    form = Admin::ChannelForm.from_params params

    begin
      if form.valid? && course_api.rel(:channels)
          .post(form.to_resource).value!
        add_flash_message :success, t(:'flash.success.channel_created')
        return redirect_to admin_channels_path
      end
    rescue Restify::UnprocessableEntity => e
      form.remote_errors e.errors
    end
    @channel = Admin::ChannelEditPresenter.new(form:)
    add_flash_message :error, t(:'flash.error.channel_not_created')
    render action: :new, status: :unprocessable_entity
  end

  def update
    authorize! 'course.channel.edit'

    form = Admin::ChannelForm.from_params params

    channel = course_api.rel(:channel).get({id: params[:id]}).value!
    form.id = channel['id']
    form.persisted!

    begin
      if form.valid? && course_api.rel(:channel)
          .patch(form.to_resource, params: {id: channel['id']}).value!
        add_flash_message :success, t(:'flash.success.channel_updated')
        return redirect_to admin_channels_path
      end
    rescue Restify::UnprocessableEntity => e
      form.remote_errors e.errors
    end
    @channel = Admin::ChannelEditPresenter.new(form:, channel:)
    add_flash_message :error, t(:'flash.error.channel_not_updated')
    render action: :edit, status: :unprocessable_entity
  end

  def destroy
    authorize! 'course.channel.delete'

    if Course::Channel.find(params[:id]).destroy
      redirect_to admin_channels_path, notice: t(:'flash.notice.channel_deleted')
    else
      redirect_to admin_channels_path, error: t(:'flash.error.channel_not_deleted')
    end
  end

  private

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
