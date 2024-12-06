# frozen_string_literal: true

class EventsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  rfc6570_params index: %i[
    collab_space_id
    course_id
    include_expired
    learning_room_id
    locale
    only_collab_space_related
    only_global
    only_learning_room_related
    user_id
  ]

  def index
    I18n.locale = params[:locale] if params[:locale].present?

    # Fetch user specific or public events?
    if params[:user_id].present?
      events = Event.for_user(params[:user_id])
    else
      events = Event.where(public: true)
    end

    # Multiple course IDs can be passed separated by slashes
    events = events.where(course_id: params[:course_id].split('/')) if params[:course_id].present?

    # Filter by collab space
    events = events.where(collab_space_id: params[:learning_room_id]) if params[:learning_room_id].present?
    events = events.where(collab_space_id: params[:collab_space_id]) if params[:collab_space_id].present?

    events = events.where(course_id: nil) if params[:only_global].present?
    events = events.where.not(collab_space_id: nil) if params[:only_learning_room_related].present?
    events = events.where.not(collab_space_id: nil) if params[:only_collab_space_related].present?

    respond_with events
  end

  def create
    event = Event.create! event_params

    # TODO: Move this to the event's create callback (once subscribers are no longer passed in)
    CreateNotificationsWorker.perform_async event.id, Array.wrap(params[:subscribers])

    render json: event
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  private

  def event_params
    # @deprecated Support old learning_room_id parameter for now
    params[:collab_space_id] = params[:learning_room_id] unless params[:learning_room_id].to_s.empty?

    # Unfortunately, #permit does not allow hashes with arbitrary keys, so we have to add :payload manually
    params.permit(:key, :public, :course_id, :collab_space_id, :link).tap do |whitelisted|
      whitelisted[:payload] = params[:payload].to_unsafe_hash if params[:payload].respond_to?(:to_unsafe_hash)
    end
  end
end
