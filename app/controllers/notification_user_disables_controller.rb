# frozen_string_literal: true

class NotificationUserDisablesController < Abstract::FrontendController
  include NotificationUserSettingsHelper
  skip_before_action :verify_authenticity_token
  before_action :set_no_cache_headers

  def show
    if params.values_at(:email, :hash, :key).any?(&:blank?)
      add_flash_message :error, t(:'flash.error.email_hash_invalid')
      redirect
      return
    end
    render
  end

  # this is used as a one click disable solution from the newsletter
  # this will set notification.email.news.announcement to false
  def create
    unless disable_notifications
      add_flash_message :error, t(:'flash.error.email_hash_invalid')
    end
    redirect
  end

  private
  def disable_notifications
    if params.values_at(:email, :hash, :key).any?(&:blank?)
      # Required parameter is missing
      return false
    end

    email = Xikolo.api(:account).value!.rel(:email)
      .get({id: params[:email]}).value!
    user = email.rel(:user).get.value!

    if hash_email(id: email['id'], user_id: user['id']) != params[:hash]
      # Security hash does not match
      return false
    end

    user
      .rel(:preferences)
      .patch({properties: {settings_key(params[:key]) => false}})
      .value!

    add_flash_message :success,
      t(:"flash.success.#{params[:key]}_mails_disabled", mail: email['address'])

    true
  rescue Restify::ClientError
    false
  end

  def redirect
    if current_user.anonymous?
      redirect_to root_path
    else
      redirect_to preferences_path
    end
  end
end
