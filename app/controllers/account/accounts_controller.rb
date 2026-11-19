# frozen_string_literal: true

class Account::AccountsController < Abstract::FrontendController
  def new
    @account = Account::AccountForm.from_params prefill_params.to_h
    @consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) unless t['required'] }
    @required_consents = treatments.filter_map {|t| ConsentPresenter.from_treatment(t) if t['required'] }
  end

  def create
    form = Account::AccountForm.from_params params

    user_treatments = AccountService::Treatment.pluck(:name).index_with do |treatment|
      given_consents.include?(treatment)
    end

    Account::Register.call(
      form, user_treatments,
      notification_emails: params[:notification_emails].present?,
      confirm: ->(email_id) { generate_confirmation_url(email_id) }
    ).on do |result|
      result.success { redirect_to verify_account_url, status: :see_other }
      result.login do |login|
        session[:id] = login.session.id
        redirect_to dashboard_path, status: :see_other
      end
      result.failure do
        @account = form
        # Restore the checkbox states from the submitted params so the user
        # does not have to tick their consents again.
        @consents = treatments.filter_map do |t|
          ConsentPresenter.from_treatment(t, consented: given_consents.include?(t['name'])) unless t['required']
        end
        @required_consents = treatments.filter_map do |t|
          ConsentPresenter.from_treatment(t, consented: given_consents.include?(t['name'])) if t['required']
        end
        render :new, status: :unprocessable_content
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

  def given_consents
    @given_consents ||= params.permit(consent: []).fetch(:consent, [])
  end

  def treatments
    @treatments ||= account_api.rel(:treatments).get.value!
  end

  def account_api
    @account_api ||= Xikolo.api(:account).value!
  end
end
