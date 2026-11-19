# frozen_string_literal: true

module AccountService
class User < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :users

  delegate :url_helpers, to: 'AccountService::Engine.routes'

  default_scope { order created_at: :asc }

  # Manual validations to remove required password on create
  has_secure_password validations: false

  validates :password,
    length: {maximum: 72, message: 'maximum_length_reached'}

  validates :password,
    length: {minimum: 8, message: 'below_minimum_length'}, unless: ->(u) { u.password.nil? }

  validate do |record|
    if record.emails.any? {|e| record.password&.include? e.address }
      record.errors.add(:password, 'password_contains_email')
    end
  end

  before_validation do
    self.state = nil if country != 'DE'
  end

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

  validates :country, length: {maximum: 100}, allow_nil: true
  validates :state, length: {maximum: 100}, allow_nil: true
  validates :city, length: {maximum: 100}, allow_nil: true

  # Exposed so the frontend registration form can apply the same rules and fail
  # before the service round-trip. Errors relayed from here are rendered in the
  # service's locale and arrive at the form as literal strings rather than
  # translatable symbols, so they cannot be localised for the user.
  NAME_MAX_LENGTH = 200
  NAME_FORMAT = %r{\A[^"/]*\z}i

  validates :full_name, presence: true, length: {maximum: NAME_MAX_LENGTH}
  validates :full_name, :display_name, format: NAME_FORMAT

  normalizes :full_name, with: ->(email) { email&.strip }
  normalizes :display_name, with: ->(display_name) { display_name&.strip }

  validate :unique_anonymous, if: :anonymous?
  validates :language, inclusion: {in: Xikolo.config.locales['available'], message: 'not_available', allow_nil: true}

  has_many :sessions, dependent: :destroy
  has_many :consents, dependent: :destroy
  has_many :authorizations, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :gamification_scores, class_name: 'Gamification::Score', dependent: :delete_all
  has_many :gamification_badges, class_name: 'Gamification::Badge', dependent: :delete_all
  has_many :item_results, class_name: 'CourseService::Result', dependent: :delete_all
  has_many :item_visits, class_name: 'CourseService::Visit', dependent: :delete_all
  has_many :certificate_records, class_name: 'Certificate::Record', dependent: :destroy
  has_many :password_resets, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :grants, as: :principal, dependent: :destroy, inverse_of: :principal
  has_many :features, as: :owner, dependent: :destroy, inverse_of: :owner
  has_many :tokens, dependent: :destroy
  has_many :user_top_talents, class_name: 'UserTopTalent', dependent: :destroy

  has_one :primary_email, -> { primary }, class_name: 'Email', inverse_of: false

  after_find :sanitize_language

  after_commit(on: %i[create update]) do
    if affiliated?
      begin
        Membership
          .where(user: self, group: Group.affiliated_users)
          .first_or_create!
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    else
      Membership
        .where(user: self, group: Group.affiliated_users)
        .destroy_all
    end
  end

  def all_groups
    groups = [
      Group.with_member(self),
      Group.all_users_scope,
    ]

    groups << Group.active_users_scope      if active?
    groups << Group.confirmed_users_scope   if confirmed?
    groups << Group.unconfirmed_users_scope unless confirmed?
    groups << Group.archived_users_scope    if archived?

    groups.reduce(&:or)
  end

  def active?
    confirmed? && !archived? && !banned? && !anonymous?
  end

  def access!
    return if last_access == Time.zone.today

    update_column :last_access, Time.zone.today # rubocop:disable Rails/SkipsModelValidations
  end

  class << self
    def with_authorization(uid)
      joins(:authorizations).where(authorizations: {uid:})
    end

    def identified_by(ident)
      where id: Email.primary.address(ident).select(:user_id)
    end

    def by_id(ids)
      where id: ids
    end

    def confirmed
      where confirmed: true
    end

    def unconfirmed
      where confirmed: false
    end

    def active
      where confirmed: true, archived: false, banned_at: nil, anonymous: false
    end

    def archived
      where archived: true
    end

    def created_last_day
      where t[:created_at].gteq(1.day.ago)
    end

    def created_last_7days
      where t[:created_at].gteq(7.days.ago)
    end

    def with_permission(permission, context: nil)
      usr_grants = Grant.for(type: User, context:)
        .with_permission(permission).select(:principal_id)
      grp_grants = Grant.for(type: Group, context:)
        .with_permission(permission).select(:principal_id)
      memberships = Membership.where(group_id: grp_grants).select(:user_id)

      merge \
        unscoped.where(id: usr_grants).or \
          unscoped.where(id: memberships)
    end

    def query(query)
      query = query.gsub(%r{[/%_]}) {|m| "\\#{m}" }
      query = "%#{query}%"

      where [
        t[:full_name].matches(query),
        t[:display_name].matches(query),
        t[:id].in(Email.address_matches(query).select(:user_id).arel),
      ].reduce(:or)
    end

    def with_embedded_resources
      select(
        'users.*',
        embed_primary_email_scope,
        embed_policy_accepted_scope
      )
    end

    private

    def embed_primary_email_scope
      Email.primary
        .where(Email.arel_table[:user_id].eq(t[:id]))
        .select(:address)
        .arel
        .as('primary_email_address')
    end

    def embed_policy_accepted_scope
      Policy
        .where(Policy.arel_table[:version].gt(t[:accepted_policy_version]))
        .arel.exists.not.as('policy_accepted')
    end

    alias t arel_table
  end

  def avatar_url
    return unless avatar_uri?
    return avatar_uri if external_avatar?

    Xikolo::S3.object(avatar_uri).public_url
  end

  def external_avatar?
    avatar_uri.present? && !avatar_uri.starts_with?('s3://')
  end

  def name
    display_name.presence || full_name
  end

  def affiliated?
    affiliated
  end

  def password=(unencrypted_password)
    @password = unencrypted_password
    super
  end

  def password_digest=(digest)
    super if digest.present?
  end

  def email(*)
    attributes['primary_email_address'] || primary_email.try(:address)
  end

  def policy_accepted?
    return attributes['policy_accepted'] if attributes.key? 'policy_accepted'

    Policy.all.empty? ||
      accepted_policy_version >= Policy.first.version
  end
  alias policy_accepted policy_accepted?

  def underage?
    AgeOfConsent.underage?(born_at)
  end

  def guardian_consent?
    guardian_consent_at.present?
  end

  def guardian_consent_required?
    underage? && !guardian_consent?
  end

  def guardian_consent=(value)
    self.guardian_consent_at =
      if ActiveModel::Type::Boolean.new.cast(value)
        guardian_consent_at || Time.zone.now
      end
  end

  def unique_anonymous
    return unless User.default_scoped.where(anonymous: true).any?

    errors.add :anonymous, 'single_record_required'
  end

  def adminize!
    ActiveRecord::Base.transaction do
      memberships.where(group: Group.administrators).first_or_create!
      memberships.where(group: Group.gdpr_admins).first_or_create!
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def deadminize!
    ActiveRecord::Base.transaction do
      memberships.where(group: Group.administrators).destroy_all
      memberships.where(group: Group.gdpr_admins).destroy_all
    end
  end

  def ban
    ActiveRecord::Base.transaction do
      update!(banned_at: Time.current, ban_count: ban_count + 1)
      sessions.destroy_all
    end
  end

  def unban
    update!(banned_at: nil)
  end

  def banned?
    banned_at.present?
  end

  def top_talent?
    user_top_talents.active.exists?
  end

  def grant_top_talent!(source:)
    with_lock do
      user_top_talents.find_or_initialize_by(source:).update!(revoked_at: nil)
      sync_top_talent!
    end
  end

  def revoke_top_talent!(source:)
    with_lock do
      record = user_top_talents.find_by(source:)
      record&.update!(revoked_at: Time.current)
      sync_top_talent!
    end
  end

  def sync_top_talent!
    # rubocop:disable-next Rails/SkipsModelValidations
    update_columns(top_talent: user_top_talents.active.exists?)
  end

  class << self
    def resolve(param)
      if param.is_a?(self)
        param
      else
        find param.to_s
      end
    end

    def authenticate(ident, password)
      user = identified_by(ident.to_s).take
      user&.authenticate password
    end

    def anonymous
      User
        .create_with(anonymous_data)
        .find_or_create_by!(anonymous: true)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    delegate :id, to: :anonymous, prefix: true

    def anonymous_data
      {
        anonymous: true,
        display_name: '',
        full_name: 'Anonymous',
        status: 'other',
      }
    end
  end

  private

  def sanitize_language
    # If the stored language is no longer valid, reset it to trigger auto-detection
    # in the frontend.
    # Do not explicitly save the record here to avoid unexpected changes in e.g.
    # other transactions only accessing users.
    # The record will be saved when it is updated for other reasons.
    if language.present? && Xikolo.config.locales['available'].exclude?(language)
      self.language = nil
    end
  end
end
end
