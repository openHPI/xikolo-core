# frozen_string_literal: true

module PeerAssessment::PermissionsHelper
  # TODO: PA introduce new roles and rights
  #
  # Ensures that the resource is owned (written/authored/created/...) by the
  # current user, except teachers/admins/editors/etc., who should have access
  # regardless of original owner if they have the according rights for a certain
  # action.
  def ensure_owner_or_permitted(resource, permission, identification_field = 'user_id')
    unless current_user_owns?(resource, identification_field) || current_user.allowed?(permission)
      raise Status::Unauthorized.new("User does not have #{permission} right.")
    end
  end

  private

  def current_user_owns?(resource, identification_field)
    resource[identification_field] == current_user.id
  end
end
