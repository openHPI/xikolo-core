# frozen_string_literal: true

class Xikolo::Account::User < Acfs::Resource
  service Xikolo::Account::Client, path: 'users'

  attribute :id, :string
  attribute :name, :string
  attribute :email, :string
  attribute :full_name, :string
  alias fullname full_name

  attribute :display_name, :string
  attribute :admin, :boolean, default: false
  alias admin? admin

  attribute :language, :string
  attribute :preferred_language, :string
  attribute :timezone, :string
  attribute :avatar_url, :string
  attribute :born_at, :date_time
  attribute :created_at, :date_time
  attribute :updated_at, :date_time

  attribute :archived, :boolean, default: false
  alias archived? archived

  attribute :confirmed, :boolean, default: false
  alias confirmed? confirmed

  attribute :affiliated, :boolean, default: false
  alias affiliated? affiliated

  attribute :policy_accepted, :boolean, default: false

  attribute :accepted_policy_version, :integer, default: 0

  # Legacy local password confirmation check
  attribute :password, :string
  validates :password, confirmation: true,
    length: {maximum: 72},
    if: ->(m) { m.password.present? }
end
