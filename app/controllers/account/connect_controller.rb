# frozen_string_literal: true

module Account
  class ConnectController < Abstract::FrontendController
    before_action do
      raise AbstractController::ActionNotFound unless current_user.anonymous?
    end

    def new
      @authorization = Account::Authorization.find params[:authorization]
    rescue ActiveRecord::RecordNotFound
      raise AbstractController::ActionNotFound
    end
  end
end
