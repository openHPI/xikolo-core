# frozen_string_literal: true

class Xikolo::Account::Token < Acfs::Resource
  service Xikolo::Account::Client, path: 'tokens'

  attribute :token, :string
  attribute :user_id, :string
  attribute :id, :string

  def user(&block)
    @user ||= Xikolo::Account::User.find user_id
    Acfs.on(@user, &block) if block
    @user
  end
end
