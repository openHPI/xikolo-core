# frozen_string_literal: true

class User < ApplicationRecord
  include NotifyOutbox

  delegate :url_helpers, to: 'Rails.application.routes'

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

  validates :full_name, presence: true, length: {maximum: 200}
  validates :full_name, :display_name, format: %r{\A[^"/]*\z}i

  validate :unique_anonymous, if: :anonymous?
  validates :language, inclusion: {in: Xikolo.config.locales['available'], message: 'not_available', allow_nil: true}

  has_many :sessions, dependent: :destroy
  has_many :consents, dependent: :destroy
  has_many :authorizations, dependent: :destroy
  has_many :emails, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :password_resets, dependent: :destroy
  has_many :groups, through: :memberships
  has_many :grants, as: :principal, dependent: :destroy, inverse_of: :principal
  has_many :features, as: :owner, dependent: :destroy, inverse_of: :owner
  has_many :tokens, dependent: :destroy

  has_one :primary_email, -> { primary }, class_name: 'Email', inverse_of: false

  after_create { notify(:create) }
  after_update { notify(:update) }
  after_destroy { notify(:destroy) }

  after_update do
    # We do not emit :confirmed if the record was created, and updated
    # to be confirmed in the same transaction. This mimics the
    # `after_commit(on: :update)` behavior.
    notify(:confirmed, skip: [:create]) if previous_changes['confirmed'] == [false, true]
  end

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
    confirmed? && !archived? && !anonymous?
  end

  def access!
    return if last_access == Time.zone.today

    update_column :last_access, Time.zone.today # rubocop:disable Rails/SkipsModelValidations
  end

  class << self
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
      where confirmed: true, archived: false, anonymous: false
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

    def search(query)
      query = query.gsub(%r{[/%_]}) {|m| "\\#{m}" }
      query = "%#{query}%"

      where [
        pref('social.allow_detection_via_display_name')
          .and(t[:display_name].matches(query)),
        pref('social.allow_detection_via_name')
          .and(t[:full_name].matches(query)),
        pref('social.allow_detection_via_email')
          .and(t[:id].in(Email.address_matches(query).select(:user_id).arel)),
      ].reduce(:or)
    end

    def auth_uid(query)
      joins(:authorizations).where(authorizations: {uid: query.to_s})
    end
    # rubocop:enable all

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

    def pref(preference)
      col   = t[:preferences]
      quote = Arel::Nodes.build_quoted("#{preference}=>false", col)

      Arel::Nodes::InfixOperation.new('@>', col, quote).not
    end
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

  def affiliation
    return if anonymous?
    return if org_name_field.blank?

    CustomField.find_by!(context: 'user', name: org_name_field)
      .custom_field_values
      .find_by(context_id: id)
      &.values&.first
  rescue ActiveRecord::RecordNotFound
    raise "User affiliation field #{org_name_field} required for JWT not found."
  end

  # TODO: enable when removing the affiliated flag
  # def affiliated
  #  @affiliated ||= Membership
  #    .where(user: self, group: Group.affiliated_group).any?
  # end
  #
  # attr_writer :affiliated

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

  def ban!
    ActiveRecord::Base.transaction do
      update!(archived: true)
      sessions.destroy_all
    end
  end

  def update_profile_completion!
    if CustomField.context('user').mandatory_completed?(self)
      features.ensure_exists! \
        name: 'account.profile.mandatory_completed',
        context: Context.root
    else
      features
        .where(name: 'account.profile.mandatory_completed')
        .destroy_all
    end
  end

  def feature?(name)
    features.where(name:).any?
  end

  alias has_feature? feature?

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
      }
    end
  end

  private

  def org_name_field
    Xikolo.config.external_booking['affiliation_field']
  end

  def publish_notify(action)
    Msgr.publish(decorate.as_event, to: "xikolo.account.user.#{action}")
  end
end
