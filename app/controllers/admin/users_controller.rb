# frozen_string_literal: true

class Admin::UsersController < Abstract::FrontendController
  def index
    authorize! 'account.user.index'
    if params[:page].nil?
      params[:page] = 1 # !TODO: Do this global for all paging support controllers?
    end

    if params[:uid_query].present?
      user = account_api.rel(:users).get({auth_uid: params[:uid_query]}).value!.first

      if user
        return redirect_to user_path user['id']
      else
        add_flash_message :error, t(:'flash.error.users.not_found')
      end
    end

    users_promise =
      if params[:q].present?
        account_api.rel(:users).get({
          query: params[:q].strip,
          page: params[:page],
        })
      else
        account_api.rel(:users).get({page: params[:page]})
      end
    @users = UserListPresenter.new users_promise
  end

  def new
    authorize! 'account.user.create'
    @user = Admin::UserForm.new
  end

  def create
    authorize! 'account.user.create'

    @user = Admin::UserForm.from_params params

    return render(action: :new) unless @user.valid?

    user = account_api.rel(:user).post(@user.to_resource).value!

    redirect_to user_path user['id']
  rescue Restify::UnprocessableEntity => e
    @user.remote_errors e.errors
    render action: :new
  end

  private

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
