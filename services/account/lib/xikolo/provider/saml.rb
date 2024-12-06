# frozen_string_literal: true

module Xikolo::Provider
  class Saml < Base
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
