# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class SAML < Base
    def data
      {
        email: info['email'],
        full_name: info['name'],
        confirmed: true,
      }
    end

    def update(user)
      ActiveRecord::Base.transaction do
        confirm_email(user)
      end
    end
  end
end
end
