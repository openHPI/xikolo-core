# frozen_string_literal: true

module Account
  class ChangePassword < ::ApplicationOperation
    ##
    # @param current_user [Xikolo::Common::Auth::CurrentUser::Authenticated]
    #   the CurrentUser object for the user who wants to change the password
    # @param params [Hash] a hash of params (with symbol keys!):
    #   :old_password, :new_password, :password_confirmation
    def initialize(current_user, params)
      super()

      @current_user = current_user
      @params = params
    end

    Success = Class.new
    Error = Struct.new(:message)

    def call
      login = {email: @current_user.email, password: @params[:old_password]}
      handler = AuthenticationHandler.new(login:)

      return error('forgot_password') unless handler.authenticated?
      return error('different_passwords') unless confirmed?

      begin
        account_api.rel(:user).patch(
          {password: @params[:new_password]},
          id: @current_user.id
        ).value!
      rescue Restify::UnprocessableEntity, Restify::NotFound
        return error('password_save_failed')
      end

      delete_user_sessions! if delete_sessions?

      result Success.new
    end

    private

    def error(type)
      result Error.new I18n.t(:"flash.error.password_change_failed.#{type}")
    end

    def confirmed?
      @params[:new_password] == @params[:password_confirmation]
    end

    def delete_sessions?
      @current_user.feature?('password_change.remove_sessions')
    end

    def delete_user_sessions!
      Account::Session
        .where(user_id: @current_user.id)
        .where.not(id: @current_user.session_id)
        .delete_all
    end

    def account_api
      @account_api ||= Xikolo.api(:account).value!
    end
  end
end
