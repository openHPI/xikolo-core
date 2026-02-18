# frozen_string_literal: true

class Admin::ChannelsOrderController < Abstract::FrontendController
  def index
    authorize! 'course.channel.index'

    @channels = Admin::ChannelOrderPresenter.new(course_api.rel(:channels).get({per_page: 250}).value!)

    render template: 'admin/channels/order'
  end

  def update
    authorize! 'course.channel.edit'

    if params[:positions].present?
      begin
        Restify::Promise.new(
          params[:positions].map.with_index(1) do |channel_id, position|
            course_api.rel(:channel).patch({position:}, params: {id: channel_id})
          end
        ).value!
        add_flash_message(:success, t(:'flash.success.channel_order_updated'))
      rescue Restify::ResponseError
        add_flash_message(:error, t(:'flash.error.channel_order_failed'))
      end
    else
      add_flash_message(:error, t(:'flash.error.channel_order_failed'))
    end

    redirect_to admin_channels_url, status: :see_other
  end

  private

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
