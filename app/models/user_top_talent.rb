# frozen_string_literal: true

class UserTopTalent < ApplicationRecord
  belongs_to :user, class_name: 'AccountService::User'

  enum :source, {
    admin: 'admin',
    course: 'course',
  }, prefix: :source

  scope :active, -> { where(revoked_at: nil) }
end
