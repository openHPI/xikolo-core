# frozen_string_literal: true

module AccountService
class PasswordReset < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :password_resets

  belongs_to :user

  before_save do
    if token.blank?
      loop do
        self.token = SecureRandom.hex(16)

        break if PasswordReset.where(token:).empty?
      end
    end
  end

  class << self
    def create_by_email(email)
      create user: User.identified_by(email).take
    end
  end

  def expired?
    created_at < 24.hours.ago
  end
end
end
