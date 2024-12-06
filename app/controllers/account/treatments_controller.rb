# frozen_string_literal: true

class Account::TreatmentsController < Abstract::FrontendController
  before_action :ensure_logged_in

  def index
    consents = user.rel(:consents).get.value!
    @required_consents = consents.filter_map {|c| ConsentPresenter.new(c) if c['required'] }
    @consents = consents.filter_map {|c| ConsentPresenter.new(c) unless c['required'] }
  end

  def consent
    consents = params[:treatments].split(',').map do |treatment|
      {
        name: treatment,
        consented: given_consents.include?(treatment),
      }
    end

    user.rel(:consents).patch(consents).value!

    add_flash_message :success, t(:'account.treatments.consent.flash.success')
    redirect_to redirect_url
  rescue Restify::ResponseError
    add_flash_message :error, t(:'account.treatments.consent.flash.error')
    redirect_to treatments_path
  end

  private

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end

  def user
    @user ||= account_api.rel(:user).get(id: current_user.id).value!
  end

  def given_consents
    @given_consents ||= params.permit(consent: []).fetch(:consent, [])
  end
end
