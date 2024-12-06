# frozen_string_literal: true

class Admin::PermissionsController < Abstract::FrontendController
  def index
    authorize! 'account.permissions.view'
    @permissions = PermissionsPresenter.new
    Acfs.run
  end

  def create
    authorize! 'account.permissions.manage'
    begin
      Xikolo.api(:account).value!.rel(:memberships).post(group: group_name, user: params[:id]).value!
    rescue Restify::ClientError
      add_flash_message :error, t(:'flash.error.user_required')
    end
    redirect_to permissions_path
  end

  def destroy
    authorize! 'account.permissions.manage'
    Xikolo.api(:account).value!.rel(:memberships).delete(group: group_name, user: params[:id]).value!
    redirect_to permissions_path
  end

  def group_name
    ['xikolo', params[:group_id]].join '.'
  end
end
