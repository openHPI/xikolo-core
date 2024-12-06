# frozen_string_literal: true

module Xikolo::Account
  class Email < Acfs::Resource
    service Xikolo::Account::Client, path: '/users/:user_id/emails'

    attribute :id, :uuid
    attribute :address, :string
    attribute :primary, :boolean
    attribute :confirmed, :boolean
    attribute :confirmed_at, :date_time
    attribute :created_at, :date_time
  end
end
