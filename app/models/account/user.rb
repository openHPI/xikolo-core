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

    enum :gender, {
      male: 'male',
      female: 'female',
      diverse: 'diverse',
      undisclosed: 'undisclosed',
    }, prefix: true

    enum :status, {
      school_student: 'school_student',
      university_student: 'university_student',
      teacher: 'teacher',
      other: 'other',
    }, prefix: true

    # Get all ISO alpha-2 country codes from the countries gem
    COUNTRY_CODES = ISO3166::Country.all.map(&:alpha2)

    # Build a hash like { US: 'US', DE: 'DE', FR: 'FR', ... }
    enum :country, COUNTRY_CODES.index_by(&:to_sym), prefix: :country

    enum :state, {
      BW: 'BW',
      BY: 'BY',
      BE: 'BE',
      BB: 'BB',
      HB: 'HB',
      HH: 'HH',
      HE: 'HE',
      MV: 'MV',
      NI: 'NI',
      NW: 'NW',
      RP: 'RP',
      SL: 'SL',
      SN: 'SN',
      ST: 'ST',
      SH: 'SH',
      TH: 'TH',
    }, prefix: :state

    def self.with_authorization(uid)
      joins(:authorizations).where(authorizations: {uid:})
    end

    def email
      primary_email&.address
    end

    def consents
      consents = Account::Consent.where(user_id: id)
      consents.map {|c| ConsentPresenter.new(c) }
    end
  end
end
