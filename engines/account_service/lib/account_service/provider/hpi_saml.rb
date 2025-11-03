# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class HPISAML < SAML
    def update(user)
      return if data[:email].blank?

      ActiveRecord::Base.transaction do
        user.update! affiliated: true if Xikolo.brand.openhpi?

        confirm_email(user)
      end
    end
  end
end
end
