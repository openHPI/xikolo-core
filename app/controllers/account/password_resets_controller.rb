# frozen_string_literal: true

class Account::PasswordResetsController < Abstract::FrontendController
  respond_to :html

  def show
    reset = account_api.rel(:password_reset).get({id: params[:id]}).value!
    @reset = Account::PasswordResetForm.from_resource reset
  rescue Restify::NotFound
    render :not_found, status: :not_found, formats: %i[html]
  end

  def new
    @reset = Account::PasswordRequestForm.new
  end

  def create
    @reset = Account::PasswordRequestForm.from_params params

    if @reset.valid?
      begin
        reset = account_api.rel(:password_resets).post(@reset.to_resource).value!

        Msgr.publish(
          {
            user_id: reset['user_id'],
            token:   reset['id'],
            url:     account_reset_url(reset['id']),
          },
          to: 'xikolo.account.password_reset.notify'
        )

        return redirect_to(
          root_url,
          notice: t(:'account.password_resets.flash.reset_send', email: params[:reset][:email])
        )
      rescue Restify::UnprocessableEntity
        @reset.errors.add :email, t(:'account.password_resets.flash.email_not_found')
      end
    end

    render :new, status: :unprocessable_entity
  end

  def update
    @reset = Account::PasswordResetForm.from_params params
    @reset.id = params['id']

    if @reset.valid?
      begin
        reset = account_api.rel(:password_reset).get({id: params[:id]}).value!
        reset.rel(:self).patch(@reset.to_resource.slice('password')).value!

        return redirect_to new_session_url, notice: t(:'account.password_resets.flash.pw_changed')
      rescue Restify::NotFound
        return render :not_found, status: :not_found
      rescue Restify::ResponseError => e
        @reset.remote_errors e.errors
      end
    end

    render :show, status: :unprocessable_entity
  end

  private

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
