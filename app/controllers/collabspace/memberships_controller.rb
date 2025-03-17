# frozen_string_literal: true

module Collabspace
  class MembershipsController < Abstract::FrontendController
    include Collabspace::FullCollabspacesControllerCommon
    include CourseContextHelper
    include Collabspace::CollabspaceHelper
    include Collabspace::ConstantsHelper

    before_action :ensure_logged_in
    before_action :ensure_admin, only: %i[update]

    def create
      status = if membership_params[:status]
                 membership_params[:status]
               elsif collabspace['kind'] == 'team'
                 MEMBERSHIP_TYPE[:admin]
               elsif collabspace['is_open']
                 MEMBERSHIP_STATUS[:member]
               else
                 MEMBERSHIP_STATUS[:pending]
               end

      begin
        collabspace.rel(:memberships).post(user_id:, status:).value!
      rescue Restify::UnprocessableEntity => e
        add_flash_message :error, t(:"learning_rooms.flash_messages.error.#{e.errors['user_id'].first}")
      end

      if status == MEMBERSHIP_STATUS[:pending]
        add_flash_message :notice, t(
          'learning_rooms.flash_messages.notice.status_pending',
          learning_room: collabspace['name']
        )
      end
      if status == MEMBERSHIP_STATUS[:member]
        add_flash_message :notice, t(
          'learning_rooms.flash_messages.notice.status_joined',
          learning_room: collabspace['name']
        )
      end
      redirect_to course_learning_room_path(course_code, collabspace['id'])
    end

    def update
      unless collabspace['kind'] == 'team'
        collabspace.rel(:memberships).get(user_id: params[:id]).then do |memberships|
          next if memberships.blank?

          if prevent_removing_last_admin?(memberships.first, collabspace)
            add_flash_message :error, t(:'learning_rooms.flash_messages.error.membership_last_admin')
            next
          end

          collabspace_api.rel(:membership).patch(
            {status: params[:status]},
            {id: memberships.first['id']}
          )
        end.value!
      end

      redirect_to edit_course_learning_room_path(course_code, collabspace['id'])
    end

    def destroy
      current = collabspace.rel(:memberships).get(user_id: current_user.id).value!.first

      unless allow_deleting_membership?(collabspace, current)
        return redirect_to course_learning_room_path(course_code, collabspace['id'])
      end

      collabspace.rel(:memberships).get(user_id: params[:id]).then do |memberships|
        next if memberships.blank?

        collabspace_api.rel(:membership).delete(id: memberships.first['id'])
      end.value!

      return redirect_to course_learning_rooms_path(course_code) if leaving_group?

      redirect_to edit_course_learning_room_path(course_code, collabspace['id'])
    end

    private

    def membership_params
      return {} unless params[:xikolo_collabspace_membership]

      params.require(:xikolo_collabspace_membership).permit :user_id, :status
    end

    def auth_context
      the_course.context_id
    end

    def course_code
      the_course.course_code
    end

    def user_id
      membership_params[:user_id] || current_user.id
    end

    def collabspace_id
      # The collabspace id is required for shared methods in the (Full)CollabspacesControllerCommon
      params[:learning_room_id]
    end

    def prevent_removing_last_admin?(membership, collabspace)
      # Only continue when an admin is about to be removed.
      return false unless membership.status == 'admin'

      # No need to block the operation if there are other admins remaining.
      remaining_admins = collabspace.rel(:memberships).get(status: 'admin').value!
      return false if (remaining_admins.count - 1).positive?

      true
    end

    def allow_deleting_membership?(collabspace, current_membership)
      return false if collabspace['kind'] == 'team' &&
                      !current_user.allowed?('course.course.teaching')

      current_user.allowed?('course.course.teaching_anywhere') ||
        (current_membership && %w[admin mentor].include?(current_membership['status'])) ||
        leaving_group?
    end

    def leaving_group?
      current_user.id == params[:id]
    end

    def collabspace
      @collabspace ||= collabspace_api.rel(:collab_space).get(id: collabspace_id).value!
    end

    def collabspace_api
      @collabspace_api ||= Xikolo.api(:collabspace).value!
    end
  end
end
