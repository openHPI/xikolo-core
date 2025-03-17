# frozen_string_literal: true

# rubocop:disable Rails/HelperInstanceVariable
# TODO: Get rid of this helper

# for controllers that just need to integrate with collabspaces (like pinboard)
module Collabspace::CollabspacesIntegrationHelper
  include Collabspace::CollabspacesControllerCommon

  def set_collabspace_variables
    return unless in_learning_room_context?

    @collabspace_presenter = build_collabspace_presenter(
      collabspace:,
      memberships: user_memberships
    )
  end

  def ensure_collabspace_membership
    return unless in_learning_room_context?

    super
  end

  def self.included(base_controller)
    if base_controller.respond_to? :before_action
      base_controller.before_action :set_collabspace_variables
      base_controller.before_action :get_course
    end
    return unless base_controller.respond_to? :helper_method

    base_controller.helper_method :in_learning_room_context?
  end

  def get_course # rubocop:disable Naming/AccessorMethodName
    @course = the_course
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
# rubocop:enable Rails/HelperInstanceVariable
