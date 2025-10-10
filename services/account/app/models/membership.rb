# frozen_string_literal: true

class Membership < ApplicationRecord
  self.table_name = :memberships

  belongs_to :user
  belongs_to :group

  validates :group, :user, presence: {message: 'required'}

  class << self
    def resolve(param)
      find UUID(param).to_s
    end

    def with_member(member)
      where user: member
    end
  end
end
