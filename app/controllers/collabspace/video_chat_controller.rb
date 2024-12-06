# frozen_string_literal: true

module Collabspace
  class VideoChatController < Abstract::FrontendController
    include CourseContextHelper
    include Collabspace::FullCollabspacesControllerCommon
    include Collabspace::ConstantsHelper

    before_action :ensure_logged_in
    before_action :ensure_collabspace_membership

    inside_course

    def index
      Acfs.run # because of `inside_course`

      @collabspace_presenter = build_collabspace_presenter(
        collabspace:,
        memberships: user_memberships,
        load_tpa: true
      )

      render 'video_chat', layout: LAYOUTS[:course_area_two_cols]
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
