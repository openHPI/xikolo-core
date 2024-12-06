# frozen_string_literal: true

module Account
  class Consent < ::ApplicationRecord
    belongs_to :user, class_name: 'Account::User'
    belongs_to :treatment, class_name: 'Account::Treatment'

    validates :value, inclusion: [true, false]

    after_save_commit do
      if consented?
        begin
          Account::Membership
            .where(user:, group: treatment.group)
            .first_or_create!
        rescue ActiveRecord::RecordNotUnique
          # do nothing
        end
      else
        Account::Membership
          .where(user:, group: treatment.group)
          .destroy_all
      end
    end

    after_destroy do
      Account::Membership
        .where(user:, group: treatment.group)
        .destroy_all
    end

    def consented?
      value
    end

    alias consented consented?

    def consented_at
      created_at
    end

    def refused?
      value.equal? false
    end
  end
end
