# frozen_string_literal: true

class MembershipDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      collab_space_id: collab_space.id,
      collab_space_name: collab_space.name,
      course_id: collab_space.course_id,
      user_id:,
      status:,
      created_at:,

      # DEPRECATED
      learning_room_id: collab_space.id,
      learning_room_name: collab_space.name,
    }.merge(urls).as_json(opts)
  end

  private

  include Rails.application.routes.url_helpers

  def urls
    {
      collab_space_url: collab_space_path(object.collab_space_id),
    }
  end
end
