# frozen_string_literal: true

module AccountService
class API::PreferencesController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def show
    respond_with user
  end

  def update
    user.preferences = user.preferences.merge params[:properties].permit!
    user.save!

    respond_with user

    Msgr.publish({user_id: user.id},
      to: 'xikolo.account.user.preferences.updated')
  end

  def decorate(resource)
    PreferencesDecorator.new resource
  end

  private

  def user
    @user ||= User.find params[:user_id]
  end
end
end
