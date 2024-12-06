# frozen_string_literal: true

module Account
  class Group < ::ApplicationRecord
    has_many :memberships,
      class_name: 'Account::Membership',
      dependent: :destroy

    class << self
      def where_member(user)
        joins(:memberships).where(memberships: {user_id: user.id})
      end
    end
  end
end
