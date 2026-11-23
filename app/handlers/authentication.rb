# frozen_string_literal: true

##
# Authentication strategies for the login flows. Each authenticator
# returns an Authentication::Result, which carries either a new session
# or a symbolic error code.
#
module Authentication
  Result = Data.define(:session, :authorization, :error, :new_authorization) do
    def self.success(session, authorization: nil, new_authorization: false)
      new(session:, authorization:, error: nil, new_authorization:)
    end

    def self.failure(error, authorization: nil, new_authorization: false)
      new(session: nil, authorization:, error:, new_authorization:)
    end

    def authenticated?
      session.present?
    end

    def new_authorization?
      new_authorization
    end

    def user_creation_required?
      error == :user_creation_required
    end

    def error_code
      error || :generic
    end
  end

  class UnsupportedAuthMethod < ArgumentError; end

  ##
  # Picks the authenticator for a submitted login form. Expects the
  # parameters to be permitted.
  #
  def self.from_params(params)
    if params[:authorization] && params[:autocreate]
      authorization = AccountService::Authorization.find(params[:authorization])
      link_authorization(authorization, auto_create: true)
    elsif params[:email].present? && params[:password].present?
      Credentials.call(ident: params[:email], password: params[:password])
    else
      raise UnsupportedAuthMethod.new "Unknown auth method: #{describe(params)}"
    end
  end

  ##
  # Summarises submitted parameters for error reports, without any of the
  # values that are filtered out of logs.
  #
  def self.describe(params)
    ActiveSupport::ParameterFilter
      .new(Rails.application.config.filter_parameters)
      .filter(params.to_h)
  end

  ##
  # Returns the symbolic reason why the account is not allowed to log in,
  # or nil if it may.
  #
  def self.login_blocked?(user)
    if !user.confirmed?
      :unconfirmed_user
    elsif user.archived?
      :archived_user
    elsif user.banned?
      :banned_user
    end
  end

  ##
  # Creates a session for the given user, unless the account is not
  # allowed to log in.
  #
  def self.start_session_for(user, authorization: nil, new_authorization: false)
    error = login_blocked?(user)

    return Result.failure(error, authorization:, new_authorization:) if error

    Result.success(AccountService::Session.create!(user:), authorization:, new_authorization:)
  end

  ##
  # Links an unconnected authorization via its provider — either to an
  # existing account with a matching email address or, with `auto_create`,
  # to a newly created one — and starts a session for it.
  #
  def self.link_authorization(authorization, auto_create:, new_authorization: false)
    user = AccountService::Provider.call(authorization, auto_create:)

    start_session_for(user, authorization:, new_authorization:)
  rescue AccountService::Provider::Error => e
    error = e.errors.include?('user_creation_required') ? :user_creation_required : :generic
    Result.failure(error, authorization:, new_authorization:)
  rescue ActiveRecord::RecordInvalid
    Result.failure(:invalid_information, authorization:, new_authorization:)
  end
end
