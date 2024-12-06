# frozen_string_literal: true

class AuthenticationHandler
  include Xikolo::Account

  attr_reader :session, :user_id, :authorization, :redirect_url

  def initialize(opts = {})
    @login         = opts[:login]
    @omniauth      = opts[:omniauth]
    @session       = opts[:session]
    @authorization = opts[:authorization]
  end

  def authenticated?
    authenticate! unless user_id || session
    session&.errors&.empty? &&
      session.valid? && session.user_id.present?
  end

  def new_authorization?
    authenticate! unless user_id || session
    authorization&.valid? && authorization.user_id.blank?
  end

  def errors
    session&.errors
  end

  def error_code
    if errors && errors.messages[:ident]
      errors.messages[:ident].first
    else
      'generic'
    end
  end

  def user_creation_required?
    errors.any? {|err| err.message == 'user_creation_required' }
  end

  def ident
    login[:email]
  end

  private

  attr_reader :login, :omniauth

  def password
    login[:password]
  end

  def autocreate?
    login[:autocreate]
  end

  def force_autocreate?
    OMNIAUTH_AUTOCREATE.include? @authorization.provider
  end

  def authenticate!
    if @session
      @user_id = @session.user_id
    elsif omniauth
      authenticate_with_omniauth!
    elsif ident.present? && password.present?
      authenticate_with_credentials!
    elsif login[:authorization] && autocreate?
      authenticate_with_autocreate!
    else
      raise UnsupportedAuthMethod.new \
        'Unknown auth method: ' \
        "#{filter(login).inspect} / " \
        "#{filter(omniauth).inspect}"
    end
  end

  def authenticate_with_credentials!
    @session = Session.create(ident:, password:)
    @user_id = @session.user_id
  end

  def authenticate_with_omniauth!
    crd = omniauth[:credentials]

    @authorization = Authorization.create \
      provider: omniauth[:provider],
      uid:      omniauth[:uid],
      token:    crd[:token],
      secret:   crd[:secret],
      expires_at: crd[:expires_at] ? Time.zone.at(crd[:expires_at]) : nil,
      info:     omniauth[:info]

    authenticate_with_authorization
  end

  def authenticate_with_autocreate!
    @session = Session.create \
      authorization: login[:authorization],
      autocreate: true

    @user_id = @session.user_id
  end

  def authenticate_with_authorization
    @session = Session.create authorization: @authorization.id, autocreate: force_autocreate?
    @user_id = @session.user_id
  end

  def filter(value)
    if value.respond_to?(:to_hash)
      parameter_filter.filter(value.to_hash)
    else
      value
    end
  end

  def parameter_filter
    @parameter_filter ||= ActiveSupport::ParameterFilter.new(
      Rails.application.config.filter_parameters
    )
  end

  class UnsupportedAuthMethod < ArgumentError; end
end
