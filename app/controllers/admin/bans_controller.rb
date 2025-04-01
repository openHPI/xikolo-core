# frozen_string_literal: true

class Admin::BansController < ApplicationController
  before_action :ensure_logged_in
  require_permission 'account.user.delete'

  def create
    if params[:user_id] == current_user.id
      add_flash_message :error, I18n.t(:'flash.error.user_self_ban')
      redirect_to user_path(params[:user_id])
      return
    end

    account_api.rel(:user_ban).post({}, params: {user_id: params[:user_id]}).value!

    add_flash_message :success, I18n.t(:'flash.success.user_banned')
    redirect_to user_path(params[:user_id])
  rescue Restify::ClientError
    add_flash_message :error, I18n.t(:'flash.error.user_not_banned')
    redirect_to user_path(params[:user_id])
  end

  private

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
