# frozen_string_literal: true

class Membership < ApplicationRecord
  self.table_name = 'collab_space_memberships'

  belongs_to :collab_space

  VALID_STATES = %w[admin pending regular mentor].freeze

  validates :user_id,
    uniqueness: {
      scope: [:collab_space_id],
      message: 'membership_exists',
    }

  validates :user_id, presence: true
  validates :status, inclusion: {in: VALID_STATES}
  validate :only_team_membership
  after_initialize :default_values

  after_create  { notify :create }
  after_destroy { notify :destroy }

  private

  def notify(type)
    Msgr.publish(
      decorate.as_json(api_version: 1),
      to: "xikolo.collabspace.membership.#{type}"
    )
  end

  def default_values
    self.status ||= 'regular'
  end

  def only_team_membership
    # We only need to validate uniqueness for team memberships
    return unless collab_space && collab_space.kind == 'team'

    team_ids = CollabSpace.where(
      course_id: collab_space.course_id,
      kind: 'team'
    ).pluck(:id)

    # do not consider update within same collab space
    team_ids.delete collab_space.id
    other_memberships = Membership
      .where(user_id:, collab_space_id: team_ids)
      .where.not(status: 'mentor')

    errors.add :user_id, 'membership_elsewhere' if other_memberships.exists?
  end
end
