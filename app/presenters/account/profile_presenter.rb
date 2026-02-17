# frozen_string_literal: true

class Account::ProfilePresenter < Presenter
  include Rails.application.routes.url_helpers
  include Xikolo::Account

  attr_accessor :profile, :user, :authorizations, :gamification

  attr_reader :badges, :scores

  def initialize(user, **opts)
    @emails = Email.where(user_id: user.id)
    @authorizations = Authorization.where(user: user.id)
    @opts = opts

    super(user:)
  end

  def user_id
    @user.id
  end

  def full_name
    @user.full_name
  end

  def name
    @user.name
  end

  def email
    @user.email
  end

  def emails
    emails = Email.where(user_id: @user.id)

    Acfs.run

    emails
  end

  def born_at
    @user.born_at.presence&.strftime('%d.%m.%Y') || not_set
  end

  def display_name
    @user.display_name.presence || not_set
  end

  def country
    @user['country'].present? ? I18n.t(:"dashboard.profile.settings.country.#{@user['country'].downcase}") : not_set
  end

  def state
    @user['state'].present? ? I18n.t(:"dashboard.profile.german_states.#{@user['state']}") : not_set
  end

  def city
    @user['city'].presence || not_set
  end

  def status
    @user['status'].present? ? I18n.t(:"dashboard.profile.statuses.#{@user['status']}") : not_set
  end

  def gender
    @user['gender'].present? ? I18n.t(:"dashboard.profile.genders.#{@user['gender']}") : not_set
  end

  def gender_collection
    Account::User.genders.keys.map {|g| [I18n.t(:"dashboard.profile.genders.#{g}"), g] }
  end

  def status_collection
    Account::User.statuses.keys.map {|s| [I18n.t(:"dashboard.profile.statuses.#{s}"), s] }
  end

  def state_collection
    %w[
      BW BY BE BB HB HH HE MV
      NI NW RP SL SN ST SH TH
    ].map {|code| [I18n.t(:"dashboard.profile.german_states.#{code}"), code] }
  end

  def unconfirmed_emails?
    unconfirmed_emails.any?
  end

  def unconfirmed_emails
    emails.reject(&:confirmed)
  end

  def secondary_emails?
    secondary_emails.any?
  end

  def secondary_emails
    emails.select {|e| e.confirmed && !e.primary }
  end

  def consents
    @consents ||= begin
      consents = if @user.respond_to?(:rel)
                   @user.rel(:consents).get.value!
                 else
                   Xikolo::Common::API.authorized_request(@user.attributes['consents_url']).get.value!
                 end
      consents.map {|c| ConsentPresenter.new(c) }
    end
  end

  def sso_providers
    @sso_providers ||= OMNIAUTH_PROVIDERS
  end

  def not_set
    I18n.t(:'dashboard.profile.not_set')
  end

  def show_state?
    @user['country'] == 'DE'
  end
end
