# frozen_string_literal: true

class AuthenticationHandler
  attr_reader :session, :params, :errors

  def initialize(params)
    @params = params
    @errors = Hash.new {|h, k| h[k] = [] }
  end

  def authenticated?
    authenticate! unless session
    session&.valid? && session&.user_id.present?
  end

  private

  def authenticate!
    if params[:authorization].present?
      authenticate_with_authorization
    elsif params[:ident].present? && params[:password].present?
      authenticate_with_credentials
    elsif params[:user].present?
      authenticate_with_user
    end
  end

  def create_session_for(user)
    return errors[:ident] << 'unconfirmed_user' unless user.confirmed?
    return errors[:ident] << 'archived_user' if user.archived?

    @session = Session.create user:, user_agent: params[:user_agent]
  end

  def authenticate_with_credentials
    user = User.authenticate(params[:ident], params[:password])

    if user
      create_session_for user
    else
      errors[:ident] << 'invalid_credentials'
    end
  rescue BCrypt::Errors::InvalidHash
    errors[:ident] << 'invalid_digest'
  end

  def authorization
    @authorization ||= Authorization.find params[:authorization]
  end

  def authenticate_with_authorization
    if authorization.user_id.present?
      create_session_for authorization.user
    else
      try_new_authorization
    end
  end

  def autocreate?
    params.fetch :autocreate, false
  end

  def try_new_authorization
    user = Xikolo::Provider.call authorization, auto_create: autocreate?

    authorization.update!(user:)
    create_session_for user
  rescue Xikolo::Provider::Error => e
    e.errors.each {|err| errors[:authorization] << err }
  rescue ActiveRecord::RecordInvalid => e
    errors[:authorization] << 'invalid_information'
    errors[:details] << e.record.errors
  end

  def authenticate_with_user
    create_session_for User.find params[:user]
  end
end
