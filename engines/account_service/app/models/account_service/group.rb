# frozen_string_literal: true

module AccountService
class Group < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :groups

  NAME_REGEXP = /\A\w+(\.(\w|-)+)+\z/
  ALLOWED_TAGS = %w[access custom_recipients].freeze

  module NAME
    ACTIVE              = 'active'
    ADMINISTRATORS      = 'xikolo.admins'
    ADMINISTRATORS_GDPR = 'xikolo.gdpr_admins'
    AFFILIATED          = 'xikolo.affiliated'
    ALL                 = 'all'
    ARCHIVED            = 'archived'
    CONFIRMED           = 'confirmed'
    UNCONFIRMED         = 'unconfirmed'
  end

  has_many :memberships, dependent: :destroy
  has_many :features, as: :owner, dependent: :destroy, inverse_of: :owner
  has_many :grants, as: :principal, dependent: :destroy, inverse_of: :principal

  has_many :members, -> { active }, through: :memberships, source: :user

  validates :name, presence: {message: 'required'}

  validates :name,
    uniqueness: {case_sensitive: false, message: 'invalid'},
    if: -> { validate_name_uniqueness.nil? || validate_name_uniqueness }

  validates :name,
    format: {message: 'invalid', with: NAME_REGEXP},
    if: -> { validate_name_format.nil? || validate_name_format }

  validate :allowed_tags

  attr_accessor :validate_name_format, :validate_name_uniqueness

  def members
    case name
      when NAME::ACTIVE
        User.active
      when NAME::ALL
        User.all
      when NAME::ARCHIVED
        User.archived
      when NAME::CONFIRMED
        User.confirmed
      when NAME::UNCONFIRMED
        User.unconfirmed
      else
        super
    end
  end

  def member_ids_relation
    case name
      when NAME::ACTIVE
        User.active.select(:id)
      when NAME::ALL
        User.select(:id)
      when NAME::ARCHIVED
        User.archived.select(:id)
      when NAME::CONFIRMED
        User.confirmed.select(:id)
      when NAME::UNCONFIRMED
        User.unconfirmed.select(:id)
      else
        memberships.select(:user_id)
    end
  end

  class << self
    def prefix(value)
      where('name LIKE ?', "#{sanitize_sql_like(value)}%")
    end

    def resolve(param)
      case param.to_s
        when NAME::ACTIVE
          active_users
        when NAME::ADMINISTRATORS
          administrators
        when NAME::ADMINISTRATORS_GDPR
          gdpr_admins
        when NAME::AFFILIATED
          affiliated_users
        when NAME::ALL
          all_users
        when NAME::ARCHIVED
          archived_users
        when NAME::CONFIRMED
          confirmed_users
        when NAME::UNCONFIRMED
          unconfirmed_users
        else
          find_by! name: param.to_s
      end
    end

    def for(principal)
      if principal.respond_to?(:all_groups)
        principal.all_groups
      else
        with_member(principal)
      end
    end

    def with_member(member)
      where id: Membership.with_member(member).select(:group_id)
    end

    def active_users
      ensure! name: NAME::ACTIVE, description: 'Active users', validate_name_format: false
    end

    def gdpr_admins
      ensure! name: NAME::ADMINISTRATORS_GDPR, description: 'Administrative users (with access to personal information)'
    end

    def administrators
      ensure! name: NAME::ADMINISTRATORS, description: 'Administrative users'
    end

    def affiliated_users
      ensure! name: NAME::AFFILIATED, description: 'Affiliated users', tags: %w[access]
    end

    def all_users
      ensure! name: NAME::ALL, description: 'All users', validate_name_format: false
    end

    def archived_users
      ensure! name: NAME::ARCHIVED, description: 'Archived users', validate_name_format: false
    end

    def confirmed_users
      ensure! name: NAME::CONFIRMED, description: 'Confirmed users', validate_name_format: false
    end

    def unconfirmed_users
      ensure! name: NAME::UNCONFIRMED, description: 'Unconfirmed users', validate_name_format: false
    end

    def active_users_id
      Rails.cache.fetch('group/id/active_users_id') { active_users.id }
    end

    def active_users_scope
      where(id: active_users_id)
    end

    def all_users_id
      Rails.cache.fetch('group/id/all_users_id') { all_users.id }
    end

    def all_users_scope
      where(id: all_users_id)
    end

    def archived_users_id
      Rails.cache.fetch('group/id/archived_users_id') { archived_users.id }
    end

    def archived_users_scope
      where(id: archived_users_id)
    end

    def confirmed_users_id
      Rails.cache.fetch('group/id/confirmed_users_id') { confirmed_users.id }
    end

    def confirmed_users_scope
      where(id: confirmed_users_id)
    end

    def unconfirmed_users_id
      Rails.cache.fetch('group/id/unconfirmed_users_id') { unconfirmed_users.id }
    end

    def unconfirmed_users_scope
      where(id: unconfirmed_users_id)
    end

    private

    def ensure!(name:, **)
      # Early check and bail if group exists
      group = find_by(name:)
      return group if group

      begin
        # Require a new transaction for creating the group to not abort
        # a parent transaction in case of concurrent modifications (and
        # following exceptions).
        #
        # We explicitly disable the name uniqueness validation since we
        # want a RecordNotUnique to be raised from the database on
        # concurrent inserts, as this will allow us to retry and pick up
        # the concurrently inserted record.
        transaction(requires_new: true) do
          Group.where(name:).first_or_create!(name:, **, validate_name_uniqueness: false)
        end
      rescue ActiveRecord::RecordNotUnique
        # Will be raised if a concurrent insertion happens in #create!,
        # after the model validation (which checks for group name
        # uniqueness), but before the INSERT.
        #
        # We can safely retry and #first_or_create! will returned the
        # concurrently inserted record.
        retry
      end
    end
  end

  def to_param
    name
  end

  private

  def allowed_tags
    errors.add(:tags, 'invalid') if (tags - ALLOWED_TAGS).any?
  end
end
end
