# frozen_string_literal: true

module Collabspace::CollabspaceHelper
  # list all users that are member in the same team as the given user
  def team_members(course_id, user_id)
    # Assumption: Each user is admin in at most one team per course (ensured by collabspace service)
    # `kind` and `course_id` are members of the collabspace but used as filters by the service
    # use collab_space instead of learning room as soon as frederikes stuff is merged
    api = Xikolo.api(:collabspace).value!
    team = api.rel(:memberships).get({user_id:, status: 'admin', kind: 'team', course_id:}).value!.first
    return [] if team.nil?

    memberships = api.rel(:memberships).get({learning_room_id: team['learning_room_id'], status: 'admin'}).value!
    memberships.pluck('user_id')
  end
end
