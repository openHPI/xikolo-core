# frozen_string_literal: true

module Xikolo::Account
  class PasswordReset < Acfs::Resource
    service Xikolo::Account::Client, path: '/password_resets'

    attribute :id, :string
    attribute :user_id, :uuid
  end
end
