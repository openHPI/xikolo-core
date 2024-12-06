# frozen_string_literal: true

module Xikolo::Account
  # = Xikolo::Account::Authorization
  #
  # An authorization is a specific authorization for an
  # external service the user has connected to.
  # Authorization are used to log in as well as store a
  # authorization token to use the service API on behalf of
  # the user.
  #
  # @example Get a user's authorizations
  #   authorizations = Xikolo::Account::Authorizations.where user: user.id
  #
  # @example Get all company SSO authorizations
  #   authorizations = Xikolo::Account::Authorizations.where \
  #     provider: 'corp'
  #
  # @example Get first company SSO authorization for given user
  #   authorization = Xikolo::Account::Authorizations.find_by \
  #     provider: 'corp', user: user.id
  #
  class Authorization < Acfs::Resource
    service Xikolo::Account::Client, path: 'authorizations'

    # Define resource attributes.
    attribute :id, :string
    attribute :user_id, :string
    attribute :provider, :string
    attribute :uid, :string
    attribute :token, :string
    attribute :secret, :string
    attribute :expires_at, :date_time
  end
end
