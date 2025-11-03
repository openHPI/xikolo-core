# frozen_string_literal: true

module AccountService
class Authorization < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :authorizations

  belongs_to :user, optional: true
  serialize :info, coder: YAML

  validates :provider, :uid, presence: true
  validate :no_existing_account_for_provider_email, if: -> { user_id.present? && info[:email].present? }, on: :update

  before_save do
    self[:info] = info.to_hash if defined?(@info)
  end

  after_commit(on: %i[create update]) do
    # Allow explicitly skipping the provider update to avoid
    # infinite callback loops via the Provider model
    Provider.update self if !skip_provider_update && user_id.present?
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
  end

  attr_accessor :skip_provider_update

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
      errors.add :provider, 'email_already_used_for_another_account'
    end
  end
end
end
