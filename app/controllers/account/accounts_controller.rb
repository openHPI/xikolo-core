# frozen_string_literal: true

class Account::AccountsController < Abstract::FrontendController
  require_feature 'account.registration'

  def new
    @account = Account::AccountForm.from_params prefill_params.to_h
    @consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) unless t['required'] }
    @required_consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) if t['required'] }
  end

  def create
    form = Account::AccountForm.from_params params

    user_treatments = {}
    if params[:consent].present?
      user_treatments = params[:treatments].split(',').index_with do |treatment|
        params[:consent].include?(treatment)
      end
    end

    Account::Register.call(
      form, user_treatments,
      confirm: ->(email_id) { generate_confirmation_url(email_id) }
    ).on do |result|
      result.success { redirect_to verify_account_url, status: :see_other }
      result.login do |login|
        session[:id] = login.session.id
        redirect_to dashboard_path, status: :see_other
      end
      result.failure do
        @account = form
        @consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) unless t['required'] }
        @required_consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) if t['required'] }
        render :new, status: :unprocessable_entity
      end
    end
  end

  def verify; end

  private

  def prefill_params
    params.permit(:full_name, :email)
  end

  def generate_confirmation_url(email_id)
    verifier = ::Account::ConfirmationsController.verifier
    payload = verifier.generate(email_id)

    account_confirmation_url(payload)
  end

  def treatments
    @treatments ||= account_api.rel(:treatments).get.value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
