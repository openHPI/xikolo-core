# frozen_string_literal: true

module Collabspace
  module Ajax
    class CalendarEventsController < Abstract::AjaxController
      include Collabspace::FullCollabspacesControllerCommon

      respond_to :json

      before_action :ensure_logged_in
      before_action :ensure_membership

      def index
        events = collabspace_api
          .rel(:calendar_events)
          .get(collab_space_id: params[:learning_room_id])
          .value!

        @events = events.map {|event| CalendarEventPresenter.create(event, view_context) }

        respond_with @events
      end

      def update
        data = params.permit(
          :start_time,
          :end_time,
          :all_day
        ).to_h

        collabspace_api.rel(:calendar_event).patch(data, id: params[:id]).value!

        head :ok
      end

      private

      def collabspace_id
        # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
        params[:learning_room_id]
      end

      def collabspace_api
        @collabspace_api ||= Xikolo.api(:collabspace).value!
      end

      def ensure_membership
        return if member?
        return if current_user.allowed? 'collabspace.space.manage'

        head :forbidden
      end

      def auth_context
        the_course.context_id
      end

      def request_course
        Xikolo::Course::Course.find params[:course_id]
      end
    end
  end
end
