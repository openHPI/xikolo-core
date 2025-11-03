# frozen_string_literal: true

module AccountService
class User::ReplaceEmails < ApplicationOperation # rubocop:disable Layout/IndentationWidth
  class OperationError < StandardError; end

  class EmptyEmailsError < OperationError; end

  class InvalidEmailsError < OperationError; end

  def initialize(user, emails)
    super()

    @user = user
    @emails = emails
  end

  def call
    raise EmptyEmailsError if @emails.blank?
    raise InvalidEmailsError unless @emails.one? {|email| email[:primary] == true }

    Email.transaction do
      @user.emails.destroy_all
      @user.emails.create!(@emails)
    end

    @user.emails
  end
end
end
