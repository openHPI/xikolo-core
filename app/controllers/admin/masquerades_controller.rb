# frozen_string_literal: true

class Admin::MasqueradesController < ApplicationController
  before_action :ensure_logged_in, only: [:destroy]

  def create
    authorize! 'account.user.masquerade'
    Xikolo.api(:account).value!.rel(:session).get(id: current_user.session_id).then do |session|
      session.rel(:masquerade).post(user: params[:user_id])
    end.value!

    # Temporarily change the CSRF token. This will cause a new CSRF
    # token to be generated on the next request, which will invalidate
    # forms opened before masquerading. This prevents already opened
    # forms from accidentally being submitted as the masqueraded user.
    # We remember the previous CSRF token so that it can be restored
    # when de-masquerading later on.
    session[:_csrf_token_pre_masquerade] = session.delete :_csrf_token
    reset_csrf_token(request)

    redirect_to dashboard_path
  end

  def destroy
    Xikolo.api(:account).value!.rel(:session).get(id: current_user.session_id).then do |session|
      session.rel(:masquerade).delete
    end.value!

    # Restore the previous CSRF token so that the admin can submit forms
    # in previously opened tabs. At the same time, this prevents
    # accidental form submissions in the opposite direction (i.e.
    # submitting forms as admin that were opened while masqueraded).
    reset_csrf_token(request)
    session[:_csrf_token] = session.delete :_csrf_token_pre_masquerade

    redirect_to user_path(params[:user_id])
  end
end
