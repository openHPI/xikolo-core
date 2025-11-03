# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class HPI < Base
    def data
      {
        email: info['email'],
        full_name: "#{info['first_name']} #{info['last_name']}".strip,
        display_name: info['nickname'],
        confirmed: true,
      }
    end

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
