# frozen_string_literal: true

module MembershipHelper
  def status_change_button(member, status, text, confirm = nil)
    button_to text,
      course_learning_room_membership_path(params[:course_id],
        params[:id],
        member.id,
        status:),
      class: 'btn btn-xs btn-primary',
      method: :patch,
      confirm:
  end
end
