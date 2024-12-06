# frozen_string_literal: true

module Account
  class Membership < ::ApplicationRecord
    belongs_to :user
    belongs_to :group, class_name: 'Account::Group'
  end
end
