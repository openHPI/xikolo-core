# frozen_string_literal: true

class Email < ApplicationRecord
  delegate :url_helpers, to: 'Rails.application.routes'

  belongs_to :user

  LCHARS = %r{\w+\p{L}\p{N}\-!/#\$%&'*+=?^`{|}~} # rubocop:disable Style/RedundantRegexpEscape
  LOCAL  = /[#{LCHARS.source}]+(\.[#{LCHARS.source}]+)*/
  DCHARS = /A-z\d/
  DOMAIN =
    /[#{DCHARS.source}][#{DCHARS.source}-]*(\.[#{DCHARS.source}-]+)*/
  EMAIL  = /\A#{LOCAL.source}@#{DOMAIN.source}\z/i

  validates :address, presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: EMAIL}

  attr_accessor :force

  validate do
    errors.add :primary, 'unconfirmed' if primary? && !confirmed? && !force
  end

  after_save do
    if confirmed?
      user.update! confirmed: true
    elsif user.emails.confirmed.empty?
      user.update! confirmed: false
    end
  end

  class << self
    def address(email)
      where arel_table[:address].lower.eq(Arel::Nodes::BindParam.new(email.downcase))
    end

    def primary
      where primary: true
    end

    def confirmed
      where confirmed: true
    end

    def address_matches(str)
      where arel_table[:address].matches(str)
    end
  end

  before_save do
    # rubocop:disable Rails/SkipsModelValidations
    user.emails.where.not(id:).update_all(primary: false) if primary?
    # rubocop:enable all
  end

  after_update(if: :primary_changed?) do
    user.notify(:update)
  end

  def primary_changed?
    previous_changes.key?('primary')
  end

  def destroyable?
    errors.add :primary, 'cannot delete' if primary?
    errors.blank?
  end

  def confirmed=(confirmed)
    return unless self.confirmed != confirmed

    self.confirmed_at = confirmed ? Time.zone.now : nil
    self[:confirmed] = confirmed
  end

  def primary=(primary)
    self[:primary] = true if primary
  end

  def primary
    self[:primary] || false
  end
  alias primary? primary

  def confirmed
    self[:confirmed] || false
  end
  alias confirmed? confirmed

  def suspend!
    user.features.ensure_exists!(
      name: 'primary_email_suspended',
      context: Context.root,
      value: Time.zone.now.iso8601
    ).new?
  end

  def unsuspend!
    user.features.where(name: 'primary_email_suspended').first!.destroy!
  end

  def to_param
    uuid
  end
end
