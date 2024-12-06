# frozen_string_literal: true

class ChannelsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    channels = Channel.where(affiliated: false)

    channels = channels.where(public: true) if params[:public] == 'true'
    channels = channels.where(highlight: true) if params[:highlight] == 'true'
    channels = channels.where(code: params[:code]) unless params[:code].nil?

    respond_with channels
  end

  def show
    respond_with channel
  end

  def create
    @channel = Channel.create! channel_params.merge(id: UUID4.new)

    respond_with @channel
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  def update
    channel.update(channel_params)
    respond_with channel
  end

  def destroy
    respond_with channel.destroy
  end

  def max_per_page
    250
  end

  private

  def channel
    @channel ||= Channel
      .where(affiliated: false)
      .by_identifier(params[:id]).take!
  end

  def channel_params
    params.permit(
      :code,
      :name,
      :logo_upload_id,
      :stage_visual_upload_id,
      :mobile_visual_upload_id,
      :stage_statement,
      :public,
      :highlight,
      :archived,
      :position
    ).tap do |white_listed|
      if params[:description]
        white_listed[:description] = params[:description].permit!
      end
      if params[:info_link]
        white_listed[:info_link] = params[:info_link].permit!
      end
    end
  end
end
