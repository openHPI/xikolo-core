# frozen_string_literal: true

class Account::ConfirmationsController < Abstract::FrontendController
  rescue_from ::ActiveSupport::MessageVerifier::InvalidSignature,
    with: :invalid_signature

  def show
    @request = params.require(:id)

    # Verify signature and fetch email to show address in template.
    address = self.class.verifier.verify(@request)
    @email = api.rel(:email).get(id: address).value!
  rescue ::Restify::NotFound
    render :confirmation_failed, status: :not_found
  end

  def new
    @request = params.require(:request)

    # Only verify here to handle invalid signatures. We're not
    # actually using the value here but passing the payload
    # to `#create` using a self-submitting form.
    self.class.verifier.verify(@request)
  end

  def create
    request = params.require(:request)
    address = self.class.verifier.verify(request)
    email   = api.rel(:email).get(id: address).value!

    verifier = self.class.verifier
    payload  = verifier.generate(email.fetch('id').to_s)
    event    = {
      id: email.fetch('id'),
      user_id: email.fetch('user_id'),
      url: account_confirmation_url(payload),
    }

    Msgr.publish(event, to: 'xikolo.account.email.confirm')

    redirect_to new_session_url, notice: t(:'flash.notice.confirmation_resend')
  end

  def update
    address = self.class.verifier.verify(params[:id])

    email = api.rel(:email).get(id: address).value!
    return render :confirmed_token, status: :gone if email['confirmed']

    email.rel(:self).patch(confirmed: true, primary: true).value!

    add_flash_message :success, t(:'flash.success.confirmation_successful')
    redirect_to new_session_url
  end

  private

  def api
    @api ||= Xikolo.api(:account).value!
  end

  def invalid_signature
    render :invalid_signature, status: :bad_request
  end

  class << self
    def verifier
      Rails.application.message_verifier('account.confirmations')
    end
  end
end
