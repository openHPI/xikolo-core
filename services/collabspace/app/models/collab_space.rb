# frozen_string_literal: true

class CollabSpace < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :calendar_events, dependent: :destroy
  has_many :files, class_name: 'UploadedFile', dependent: :destroy

  validates :name, presence: true
  validates :is_open, inclusion: {in: [true, false]}
  validate :team_validations
  validates :description, length: {maximum: 400}

  after_create  { notify :create }
  after_update  { notify :update }
  after_destroy { notify :destroy }

  default_scope { order created_at: :asc }

  scope :only_teams, -> { where kind: 'team' }

  def owner_id=(owner_id)
    add_member owner_id, 'admin' unless owner_id.nil?
  end

  def add_member(member_id, status = 'regular')
    memberships << Membership.new(user_id: member_id, status:)
  end

  def member?(member_id)
    find_membership member_id
  end

  def remove_member(member_id)
    membership = find_membership member_id
    if membership
      membership.destroy
    else
      false
    end
  end

  def open?
    is_open
  end

  def private?
    !open?
  end

  def team?
    kind == 'team'
  end

  private

  def find_membership(member_id)
    memberships.find_by(user_id: member_id)
  end

  def notify(type)
    Msgr.publish(
      decorate.as_json(api_version: 1),
      to: "xikolo.collabspace.collab_space.#{type}"
    )
  end

  def team_validations
    valid = team? && is_open
    errors.add(:is_open, 'team collab spaces must always be closed') if valid
  end
end
