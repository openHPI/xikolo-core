# frozen_string_literal: true

module Xikolo::Account
  class Features < Acfs::SingletonResource
    service Xikolo::Account::Client, path: '/users/:user_id/features'

    delegate :[], :fetch, :key?, :has_key?, :have_key?, to: :attributes
  end
end
