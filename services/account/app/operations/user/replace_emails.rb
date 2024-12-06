# frozen_string_literal: true

class User::ReplaceEmails < ApplicationOperation
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
