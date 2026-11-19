# frozen_string_literal: true

class Admin::BansController < ApplicationController
  before_action :ensure_logged_in
  require_permission 'account.user.delete'

  def create
    if params[:user_id] == current_user.id
      add_flash_message :error, I18n.t(:'flash.error.user_self_ban')
      redirect_to user_path(params[:user_id]), status: :see_other
      return
    end

    if AccountService::User.find(params[:user_id]).ban
      add_flash_message :success, I18n.t(:'flash.success.user_banned')
    else
      add_flash_message :error, I18n.t(:'flash.error.user_not_banned')
    end

    redirect_to user_path(params[:user_id]), status: :see_other
  end

  def destroy
    AccountService::User.find(params[:user_id]).unban
    NotificationService::SendAccountReactivationEmailJob.perform_later(
      user_id: params[:user_id],
      url: new_session_url
    )
    add_flash_message :success, I18n.t(:'flash.success.user_unbanned')
  rescue ActiveRecord::RecordInvalid
    add_flash_message :error, I18n.t(:'flash.error.user_not_unbanned')
  ensure
    redirect_to user_path(params[:user_id]), status: :see_other
  end
end
