# frozen_string_literal: true

class CollabSpaceDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      name:,
      is_open: open?,
      course_id:,
      kind:,
      description:,
      details:,
    }.merge(urls).as_json(opts)
  end

  private

  include Rails.application.routes.url_helpers

  def urls
    {
      url: collab_space_path(object),
      memberships_url: memberships_path(collab_space_id: object.id),
      calendar_events_url: calendar_events_path(collab_space_id: object.id),
      files_url: collab_space_files_path(collab_space_id: object.id),
    }
  end
end
