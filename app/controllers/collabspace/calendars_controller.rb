# frozen_string_literal: true

module Collabspace
  class CalendarsController < Abstract::FrontendController
    include Interruptible

    include CourseContextHelper
    include Collabspace::FullCollabspacesControllerCommon

    require_feature 'collabspace_calendar'
    inside_course

    layout 'course_area_two_cols'

    before_action :ensure_logged_in
    before_action :ensure_collabspace_membership

    def show
      Acfs.run # because of `inside_course`

      @collabspace_presenter = build_collabspace_presenter(
        collabspace:,
        memberships: user_memberships,
        load_tpa: true
      )
    end

    private

    def auth_context
      the_course.context_id
    end

    def collabspace_id
      # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
      params[:learning_room_id]
    end

    def collabspace
      @collabspace ||= Xikolo.api(:collabspace).value!
        .rel(:collab_space)
        .get(id: collabspace_id)
        .value!
    end
  end
end
