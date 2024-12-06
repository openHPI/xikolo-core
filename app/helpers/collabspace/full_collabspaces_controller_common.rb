# frozen_string_literal: true

# for controllers that are for collabspaces only (unlike Pinboards)
module Collabspace::FullCollabspacesControllerCommon
  include Collabspace::CollabspacesControllerCommon

  def in_learning_room_context?
    true
  end

  def self.included(base_controller)
    return unless base_controller.respond_to? :helper_method

    base_controller.helper_method :in_learning_room_context?
  end
end
