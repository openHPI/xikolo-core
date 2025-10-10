# frozen_string_literal: true

module AccountService
class API::MasqueradesController < API::RESTController # rubocop:disable Layout/IndentationWidth
  def create
    if user
      session.masquerade! user

      render status: :ok, json: {}
    else
      render status: :unprocessable_content,
        json: {errors: {user: %w[required]}}
    end
  end

  def destroy
    session.demasquerade!

    render status: :ok, json: {}
  end

  private

  def session
    Session.resolve params[:session_id]
  end

  def user
    User.resolve params[:user] if params[:user].present?
  end
end
end
