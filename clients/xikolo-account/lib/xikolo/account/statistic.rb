# frozen_string_literal: true

class Xikolo::Account::Statistic < Acfs::SingletonResource
  service Xikolo::Account::Client, path: 'statistic'

  attribute :confirmed_users, :integer
  attribute :confirmed_users_last_day, :integer
  attribute :unconfirmed_users_last_7days, :integer
  attribute :users_deleted, :integer
end
