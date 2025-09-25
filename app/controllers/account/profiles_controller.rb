# frozen_string_literal: true

class Account::ProfilesController < Abstract::FrontendController
  include Xikolo::Account

  require 'marcel'
  require_feature 'profile'
  before_action :ensure_logged_in
  include Interruptible

  def show
    @profile = Account::ProfilePresenter.new(find_user, native_login: current_user.feature?('account.login'))
    Acfs.run

    set_page_title t(:'header.navigation.profile')
    render layout: 'dashboard'
  end

  def edit
    @user ||= find_user
    @profile = Account::ProfilePresenter.new(@user, native_login: current_user.feature?('account.login'))

    Acfs.run

    set_page_title t(:'header.navigation.profile')
    render layout: 'dashboard'
  end

  def edit_email
    @profile = Account::ProfilePresenter.new(find_user, native_login: current_user.feature?('account.login'))
    @email = Email.new

    Acfs.run

    set_page_title t(:'header.navigation.profile')
    render layout: 'dashboard'
  end

  def edit_avatar
    @user = find_user

    set_page_title t(:'header.navigation.profile')
    render layout: 'dashboard'
  end

  def update
    @user = find_user

    if @user.update_attributes(user_params)
      add_flash_message :success, t(:'flash.success.profile_updated')
      redirect_to dashboard_profile_path
    else
      add_flash_message :error, t(:'flash.error.profile_not_updated')
      @profile = Account::ProfilePresenter.new(@user, native_login: current_user.feature?('account.login'))
      render 'edit', layout: 'dashboard'
      nil
    end
  end

  def update_email
    email = Email.create(user_id: current_user.id, address: email_params[:address])

    if email.errors.present?
      add_flash_message :error, t(:"flash.error.email_error_#{email.errors.first.type}")
    else
      verifier = ::Account::ConfirmationsController.verifier
      payload = verifier.generate(email.id.to_s)

      Msgr.publish({
        user_id: current_user.id,
        id: email.id,
        url: account_confirmation_url(payload),
      }, to: 'xikolo.account.email.confirm')

      add_flash_message :notice, t(:'flash.notice.confirmation_email_required', email: email.address)
    end
    redirect_to profile_edit_email_path
  end

  def unsuspend_primary_email
    user  = Xikolo.api(:account).value!.rel(:user).get({id: current_user.id}).value!
    email = user.rel(:emails).get.value!
      .find {|e| e['primary'] }
    email.rel(:suspension).delete.value!

    add_flash_message :success, t(:'flash.success.primary_email_unsuspended')
    redirect_to profile_path
  end

  def delete_authorization
    Authorization.find params[:id] do |auth|
      if auth.user_id == current_user.id
        auth.delete
        add_flash_message :notice, t(:'flash.notice.auth_deleted')
      else
        add_flash_message :error, t(:'flash.error.auth_delete_failed')
      end
    end
    Acfs.run

    redirect_to profile_path
  end

  def delete_email
    email = Email.find(params[:id], params: {user_id: current_user.id})
    begin
      Acfs.run
    rescue Acfs::ResourceNotFound
      # it's already gone
      return redirect_to profile_path
    end

    email.delete

    add_flash_message :success, t(:'flash.success.email_deleted')
    redirect_to profile_path
  end

  def change_primary_email
    mail = Email.find(params[:id], params: {user_id: current_user.id})
    Acfs.run
    email = account_api.rel(:email).get({id: mail.address}).value!
    email.rel(:self).patch({primary: true}).value!

    redirect_to profile_path
  end

  def update_visual
    if params[:xikolo_account_user].present?
      @user = find_user

      if avatar_params[:avatar_upload_id].present?
        @user.update_attributes({avatar_upload_id: avatar_params[:avatar_upload_id]})

        if @user.errors.present?
          add_flash_message :error, t(:"flash.error.upload_#{@user.errors.first.type}")
        else
          add_flash_message :success, t(:'flash.success.profile_picture_uploaded')
        end
      else
        @user.update_attributes({avatar_uri: nil})

        if @user.errors.present?
          add_flash_message :error, t(:'flash.error.profile_picture_not_deleted')
        else
          add_flash_message :success, t(:'flash.success.profile_picture_deleted')
        end
      end
    end

    redirect_to dashboard_profile_path
  end

  def change_my_password
    Account::ChangePassword.call(
      current_user, password_params
    ).on do |result|
      result.success { add_flash_message :notice, t(:'flash.notice.password_changed') }
      result.error {|e| add_flash_message :error, e.message }
    end

    redirect_to dashboard_profile_path
  end

  private

  def user_params
    params.require(:xikolo_account_user).permit(:full_name, :display_name, :born_at, :status, :country, :state,
      :city, :gender).transform_values(&:presence)
  end

  def avatar_params
    params.require(:xikolo_account_user).permit(:avatar_upload_id)
  end

  def email_params
    params.require(:xikolo_account_email).permit(:address)
  end

  def password_params
    params.require(:xikolo_account_user).permit(:old_password, :new_password, :password_confirmation)
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def find_user
    user = User.find current_user.id
    Acfs.run

    user
  end
end
