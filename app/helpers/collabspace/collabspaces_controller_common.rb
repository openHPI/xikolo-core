# frozen_string_literal: true

# TODO: Get rid of this helper
module Collabspace::CollabspacesControllerCommon
  def build_collabspace_presenter(collabspace:, memberships:)
    Collabspace::CollabspacePresenter.create(
      collabspace,
      the_course,
      request:,
      membership:,
      include_calendar: current_user.feature?('collabspace_calendar'),
      super_privileged: current_user.allowed?('course.course.teaching_anywhere'),
      user_memberships: memberships.presence || []
    )
  end

  def ensure_collabspace_membership
    return if current_user.allowed_any? \
      'course.course.teaching_anywhere',
      'collabspace.space.manage'
    return if member?

    add_flash_message :error, t(:'flash.error.need_to_be_member')
    redirect_to(course_learning_rooms_path(params[:course_id]))
  end

  def ensure_admin
    return if current_user.allowed_any? \
      'course.course.teaching_anywhere',
      'collabspace.space.manage'
    return if privileged?

    add_flash_message :error, t(:'flash.error.need_to_be_admin')
    redirect_to(course_learning_room_path(params[:course_id], collabspace_id))
  end

  private

  def collabspace_api
    @collabspace_api ||= Xikolo.api(:collabspace).value!
  end

  def membership
    @membership ||= user_memberships&.first
  end

  def user_memberships
    @user_memberships ||= collabspace_api
      .rel(:memberships)
      .get(collab_space_id: collabspace_id, user_id: current_user.id)
      .value!
  end

  def member?
    !membership.nil? && membership['status'] != 'pending'
  end

  def privileged?
    !membership.nil? &&
      %w[admin mentor].include?(membership['status'])
  end

  def course_items
    @course_items ||= Xikolo.api(:course).value!.rel(:items)
  end
end
# rubocop:enable all
