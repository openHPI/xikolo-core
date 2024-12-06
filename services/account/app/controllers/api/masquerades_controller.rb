# frozen_string_literal: true

class API::MasqueradesController < API::RESTController
  def create
    if user
      session.masquerade! user

      render status: :ok, json: {}
    else
      render status: :unprocessable_entity,
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
