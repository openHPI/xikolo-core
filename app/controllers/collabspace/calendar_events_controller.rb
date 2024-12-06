# frozen_string_literal: true

module Collabspace
  class CalendarEventsController < Abstract::FrontendController
    include Collabspace::FullCollabspacesControllerCommon

    respond_to :html

    require_feature 'collabspace_calendar'

    before_action :ensure_logged_in
    before_action :ensure_collabspace_membership
    before_action :ensure_owner_or_admin, only: %i[update destroy]

    layout 'modal'

    def new
      @event_form = CalendarEventForm.new \
        'start_time' => params[:start_time],
        'end_time' => params[:end_time],
        'all_day' => params[:all_day]
    end

    def edit
      event = load_event!(params.require(:id))
      @event_form = CalendarEventForm.from_resource(event)
    end

    def create
      form = CalendarEventForm.from_params(params)
      form.user_id = current_user.id
      form.collab_space_id = params[:learning_room_id]

      unless form.valid?
        @event_form = form
        return render :new
      end

      new_event = collabspace_api
        .rel(:calendar_events)
        .post(form.to_resource)
        .value!
      @event = CalendarEventPresenter.create(new_event, view_context)

      render :confirmation
    rescue Restify::UnprocessableEntity => e
      @event_form = form
      @event_form.remote_errors e.errors
      render :new
    end

    def update
      form = CalendarEventForm.from_params(params)
      form.user_id = current_user.id
      form.collab_space_id = params.require(:learning_room_id)
      id = params.require(:id)

      unless form.valid?
        @event_form = persist_form(form, id)
        return render :edit
      end

      updated_event = collabspace_api
        .rel(:calendar_event)
        .patch(form.to_resource, id:)
        .value!
      @event = CalendarEventPresenter.create(updated_event, view_context)

      render :confirmation
    rescue Restify::UnprocessableEntity => e
      @event_form = persist_form(form, id)
      @event_form.remote_errors e.errors
      render :edit
    end

    def destroy
      id = params.require(:id)
      collabspace_api.rel(:calendar_event).delete(id:).value!
      render :confirmation
    end

    private

    def load_event!(id)
      collabspace_api.rel(:calendar_event).get(id:).value!
    end

    def persist_form(form, id)
      form.persisted!
      form.id = id
      form
    end

    def collabspace_id
      # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
      params[:learning_room_id]
    end

    def collabspace_api
      @collabspace_api ||= Xikolo.api(:collabspace).value!
    end

    def ensure_owner_or_admin
      ownership = collabspace_api
        .rel(:calendar_event)
        .get(id: params[:id])
        .value!&.fetch('user_id')

      return if ownership == current_user.id || privileged?
      return if current_user.allowed? 'collabspace.space.manage'

      add_flash_message :error, t(:'flash.error.need_to_be_member')
      redirect_to(course_learning_rooms_path(params[:course_id], params[:learning_room_id]))
    end

    def auth_context
      the_course.context_id
    end

    def request_course
      Xikolo::Course::Course.find params[:course_id]
    end
  end
end
