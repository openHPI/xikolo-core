# frozen_string_literal: true

module AccountService
class Token < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :tokens

  belongs_to :user, optional: true
  belongs_to :owner, polymorphic: true

  before_create :generate_token

  def owner
    super || user
  end

  private

  def generate_token
    loop do
      self.token = SecureRandom.hex(32)

      break unless Token.default_scoped.exists?(token:)
    end
  end
end
end
