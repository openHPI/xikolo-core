# frozen_string_literal: true

class MessagesController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json

  def show
    respond_with Message.find(params[:id])
  end

  def create
    message = Message::Create.call announcement, message_params

    respond_with message, json: {}
  end

  def decoration_context
    @decoration_context ||= params.permit(:language)
  end

  private

  def announcement
    @announcement ||= Announcement.find params.require(:announcement_id)
  end

  def message_params
    %i[creator_id recipients consents is_test].zip(
      [*params.require(%i[creator_id recipients]), params[:consents], params[:test] == true]
    ).to_h
  end
end
