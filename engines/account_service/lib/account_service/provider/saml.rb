# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class SAML < Base
    def data
      {
        email: info['email'],
        full_name: info['name'],
        confirmed: true,
        status: 'other',
      }
    end

    def update(user)
      return if data[:email].blank?

      ActiveRecord::Base.transaction do
        confirm_email(user)
      end
    end
  end
end
end
