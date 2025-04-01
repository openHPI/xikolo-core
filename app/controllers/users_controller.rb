# frozen_string_literal: true

class UsersController < Abstract::FrontendController
  include SessionHelper
  before_action :ensure_logged_in

  def show
    user = account_api.rel(:user).get({id: params[:id]}).value!
    teacher = course_api.rel(:teachers).get({user_id: params[:id]}).value!.first

    @profile = UserProfilePresenter.new(current_user, UserPresenter.new(user))
    @teacher = Course::TeacherListPresenter::TeacherPresenter.new(teacher) if teacher.present?
  rescue Restify::NotFound
    raise AbstractController::ActionNotFound
  end

  def destroy
    authorize! 'account.user.delete' if params[:id] != current_user.id

    account_api.rel(:user).delete({id: params[:id]}).value!

    if params[:id] == current_user.id
      logout
      add_flash_message :notice, t(:'flash.notice.user_deleted')
      redirect_to after_sign_out_path
    else
      add_flash_message :notice, t(:'flash.notice.user_deleted_by_admin')
      redirect_to users_path
    end
  end

  def change_user_password
    authorize! 'account.user.change_password'

    account_api.rel(:user).patch({password: password_params[:password]}, params: {id: params[:id]}).value!

    add_flash_message :notice, t(:'flash.notice.password_changed')
    redirect_to user_path(id: params[:id])
  rescue Restify::UnprocessableEntity, Restify::NotFound
    add_flash_message :error, t(:'flash.error.password_change_failed.password_save_failed')
    redirect_to user_path(id: params[:id])
  end

  private

  def password_params
    params.require(:user).permit :password
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
