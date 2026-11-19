# frozen_string_literal: true

module Account
  ##
  # Underage users have to confirm that a legal guardian approves their
  # registration. New accounts do so on the registration form; accounts that
  # predate the requirement are interrupted and sent here.
  class GuardianConsentsController < Abstract::FrontendController
    before_action :ensure_logged_in
    before_action :ensure_underage

    def update
      # The checkbox is only marked `required` in the browser, so the consent
      # has to be checked for here as well.
      unless consented?
        add_flash_message :error, t(:'account.guardian_consents.update.flash.error')
        return redirect_to account_guardian_consent_path, status: :see_other
      end

      user.update!(guardian_consent: true)

      redirect_to redirect_url, status: :see_other
    end

    private

    def ensure_underage
      raise Status::NotFound unless user.underage?
    end

    def consented?
      params[:guardian_consent] == 'true'
    end

    def user
      @user ||= AccountService::User.find(current_user.id)
    end
  end
end
