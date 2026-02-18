# frozen_string_literal: true

class Admin::ManualConfirmationsController < ApplicationController
  require_permission 'account.user.confirm_manually'

  def create
    user = Xikolo.api(:account).value!.rel(:user).get({id: params[:user_id]}).value!
    email = user.rel(:emails).get.value!.first
    email.rel(:self).patch({confirmed: true, primary: true}).value!

    add_flash_message(:success, t(:'flash.success.account_confirmed_manually'))
    redirect_to user_path(id: params[:user_id]), status: :see_other
  rescue Restify::ResponseError
    add_flash_message(:error, t(:'flash.error.account_not_confirmed_manually'))
    redirect_to user_path(id: params[:user_id]), status: :see_other
  end
end
