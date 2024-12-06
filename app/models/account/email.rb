# frozen_string_literal: true

module Account
  class Email < ::ApplicationRecord
    belongs_to :user, class_name: 'Account::User'

    class << self
      def primary
        where(primary: true)
      end
    end
  end
end
