# frozen_string_literal: true

module Account
  class User < ::ApplicationRecord
    has_many :authorizations, dependent: :destroy

    has_many :gamification_scores, class_name: 'Gamification::Score', dependent: :delete_all
    has_many :gamification_badges, class_name: 'Gamification::Badge', dependent: :delete_all

    has_many :memberships,
      class_name: 'Account::Membership',
      dependent: :destroy
    has_many :emails, class_name: 'Account::Email', dependent: :destroy
    has_one :primary_email, -> { primary }, class_name: 'Account::Email', inverse_of: false # rubocop:disable Rails/HasManyOrHasOneDependent

    has_many :item_results,
      class_name: '::Course::Result',
      dependent: :delete_all
    has_many :item_visits,
      class_name: '::Course::Visit',
      dependent: :delete_all

    has_many :certificate_records,
      class_name: '::Certificate::Record',
      dependent: :destroy

    def self.with_authorization(uid)
      joins(:authorizations).where(authorizations: {uid:})
    end

    def email
      primary_email&.address
    end
  end
end
