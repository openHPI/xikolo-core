# frozen_string_literal: true

class Account::TestController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show; end

  def update
    reset_session
    session[:id] = params[:session_id]
  end
end
