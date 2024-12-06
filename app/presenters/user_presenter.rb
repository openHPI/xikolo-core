# frozen_string_literal: true

class UserPresenter
  extend RestifyForwardable
  include Rails.application.routes.url_helpers

  def_restify_delegators :@user, :id, :email, :name, :full_name,
    :display_name, :born_at, :to_param, :language

  def initialize(user)
    @user = user
  end

  def form
    Admin::UserForm.from_resource @user
  end

  def admin?
    false
  end

  def confirmed?
    @user['confirmed']
  end

  def archived?
    @user['archived']
  end

  def all_emails
    Account::User.find(@user.id).emails
  end
end
