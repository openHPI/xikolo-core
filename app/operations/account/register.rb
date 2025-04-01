# frozen_string_literal: true

class Account::Register < ApplicationOperation
  ##
  # Parameters:
  # - a filled-out Account::AccountForm object
  # - a hash of treatment names mapped to booleans (whether the user consented or not)
  # - a block that, given an email ID, can generate a confirmation URL
  #
  def initialize(form, treatments, confirm:)
    super()

    @form = form
    @treatments = treatments
    @confirm = confirm
  end

  Success = Class.new
  Login = Struct.new(:session)
  Failure = Struct.new(:errors)

  def call
    return result Failure.new(@form.errors) unless @form.valid?

    user = account_api.rel(:users).post(@form.to_resource)
    policy = account_api.rel(:policies).get.then(&:first)

    [
      load_email(user.value!).then do |email|
        trigger_welcome_mail user.value!, email if email
      end,
      consent!(user.value!),
      accept_policy!(user.value!, policy.value!),
    ].compact.each(&:value!)

    result Success.new
  rescue Restify::ResponseError => e
    result handle_error(e)
  end

  private

  def load_email(user)
    user.rel(:emails).get.then(&:first)
  end

  def consent!(user)
    return if @treatments.blank?

    consents = @treatments.map do |name, consented|
      {name:, consented:}
    end

    user.rel(:consents).patch(consents)
  end

  def accept_policy!(user, policy)
    return unless policy

    user.rel(:self).patch({accepted_policy_version: policy['version']})
  end

  def trigger_welcome_mail(user, email)
    Msgr.publish({
      user_id: user['id'],
      confirmation_url: @confirm.call(email['id'].to_s),
    }, to: 'xikolo.web.account.sign_up')
  end

  def handle_error(exception)
    # When the email is already known, the user is probably mistaking the
    # registration form as a login form. If we can log them in using the given
    # credentials, we silently do so instead of complaining.
    if exception.errors['email']&.first == 'has already been taken'
      if (session = try_authenticate)
        return Login.new(session)
      end

      exception.errors['email'][0] = 'already_taken'
    end

    @form.remote_errors exception.errors

    Failure.new(@form.errors)
  end

  def try_authenticate
    return if @form.email.blank? || @form.password.blank?

    session = Xikolo::Account::Session.create ident: @form.email, password: @form.password
    session if session.valid?
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
