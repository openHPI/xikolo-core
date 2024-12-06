# frozen_string_literal: true

module Xikolo::Account
  class Session < Acfs::Resource
    service Xikolo::Account::Client, path: 'sessions'

    attribute :id, :string
    attribute :user_id, :string
    attribute :user_agent, :string
  end
end
