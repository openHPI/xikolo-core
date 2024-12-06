# frozen_string_literal: true

require 'api_responder'

class CalendarEventsController < ApplicationController
  self.responder = ::APIResponder

  respond_to :json

  rfc6570_params index: %i[collab_space_id]

  def index
    respond_with CalendarEvent.where(
      collab_space_id: params.require(:collab_space_id)
    )
  end

  def create
    respond_with CalendarEvent.create(create_calendar_event_params)
  end

  def show
    respond_with CalendarEvent.find(params.require(:id))
  end

  def update
    event = CalendarEvent.find(params.require(:id))
    event.update(update_calendar_event_params)
    respond_with event
  end

  def destroy
    event = CalendarEvent.find(params.require(:id))
    event.destroy
    respond_with event
  end

  private

  def create_calendar_event_params
    params.permit :collab_space_id,
      :title,
      :description,
      :start_time,
      :end_time,
      :category,
      :user_id,
      :all_day
  end

  def update_calendar_event_params
    params.permit :title,
      :description,
      :start_time,
      :end_time,
      :category,
      :all_day
  end
end
