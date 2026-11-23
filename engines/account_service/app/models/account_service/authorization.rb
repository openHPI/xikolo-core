# frozen_string_literal: true

module AccountService
class Authorization < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :authorizations

  # Added to the `:provider` attribute when the authorization cannot be
  # connected because its e-mail address already belongs to another account.
  EMAIL_ALREADY_USED = 'email_already_used_for_another_account'

  belongs_to :user, optional: true
  serialize :info, coder: YAML

  validates :provider, :uid, presence: true
  validate :no_existing_account_for_provider_email, if: -> { user_id.present? && info[:email].present? }, on: :update

  before_save do
    self[:info] = info.to_hash if defined?(@info)
  end

  after_commit(on: %i[create update]) do
    Provider.update self if user_id.present?
  end

  class << self
    def provider(provider)
      where provider:
    end

    def user(user)
      where user:
    end

    def uid(uid)
      where uid:
    end

    ##
    # Finds or initializes an authorization from an OmniAuth payload and
    # updates it with the given credentials and profile information.
    #
    def from_omniauth(payload)
      credentials = payload[:credentials] || {}

      authorization = find_or_initialize_by(
        provider: payload[:provider].to_s,
        uid: payload[:uid].to_s
      )
      info = payload[:info].presence || authorization.info
      attributes = {
        token: credentials[:token],
        secret: credentials[:secret],
        expires_at: (Time.zone.at(credentials[:expires_at]) if credentials[:expires_at]),
        info:,
      }
      # Blank credentials must not erase the ones stored for a previous login.
      authorization.assign_attributes(attributes.compact)
      authorization.save!
      authorization
    rescue ActiveRecord::RecordNotUnique
      # A concurrent login created the authorization first. Retrying picks it up.
      retry
    end
  end

  def info
    @info ||= ActiveSupport::HashWithIndifferentAccess.new self[:info]
  end

  def info=(info)
    @info = ActiveSupport::HashWithIndifferentAccess.new info
  end

  private

  # When a user_id is assigned to an authorization, there must not be an existing account
  # with the email address provided by the authorization
  def no_existing_account_for_provider_email
    email = Email.address(info[:email]).take
    return unless email

    if email.user_id != user_id
      errors.add :provider, EMAIL_ALREADY_USED
    end
  end
end
end
