# frozen_string_literal: true

class Admin::UsersController < Abstract::FrontendController
  def index
    authorize! 'account.user.index'

    users = AccountService::User.where(archived: false)
    users = filter_by_status(users)

    if params[:q].present?
      users = users.query(params[:q])
    end

    @users = users
      .unscope(:order)
      .order('lower(full_name) asc')
      .paginate(page: params[:page], per_page: 10)
  end

  private

  def filter_by_status(users)
    case params[:status]
      when 'banned'
        users.where.not(banned_at: nil)
      when 'confirmed'
        users.confirmed
      when 'unconfirmed'
        users.unconfirmed
      when 'top_talent'
        users.where(top_talent: true)
      else
        users
    end
  end
end
