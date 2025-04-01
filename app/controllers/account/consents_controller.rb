# frozen_string_literal: true

class Account::ConsentsController < Abstract::AjaxController
  before_action :ensure_logged_in

  def update
    return if consent_params.blank?

    res = user.rel(:consents)
      .patch(consent_params.map {|k, v| {name: k, consented: v != 'false'} })
      .value!

    render json: res.select {|c| consent_params.key?(c['name']) }
      .map {|c| ConsentPresenter.new(c) }
  end

  private

  def consent_params
    params.permit(treatments).to_h
  end

  def treatments
    @treatments ||= account_api.rel(:treatments).get.value&.pluck('name')
  end

  def user
    @user ||= account_api.rel(:user).get({id: current_user.id}).value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
