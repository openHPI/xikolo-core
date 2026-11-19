# frozen_string_literal: true

class Admin::TopTalentsController < ApplicationController
  before_action :ensure_logged_in
  require_permission 'account.user.delete'

  def create
    AccountService::User.find(params[:user_id]).grant_top_talent!(source: 'admin')
    add_flash_message :success, I18n.t(:'flash.success.user_marked_top_talent')
    redirect_to user_path(params[:user_id]), status: :see_other
  end

  def destroy
    AccountService::User.find(params[:user_id]).revoke_top_talent!(source: 'admin')
    add_flash_message :success, I18n.t(:'flash.success.user_unmarked_top_talent')
  ensure
    redirect_to user_path(params[:user_id]), status: :see_other
  end
end
