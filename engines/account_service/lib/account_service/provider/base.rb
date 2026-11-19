# frozen_string_literal: true

module AccountService
module Provider # rubocop:disable Layout/IndentationWidth
  class Base
    attr_reader :authorization

    def initialize(authorization)
      @authorization = authorization
    end

    delegate :info, to: :authorization
    delegate :uid, to: :authorization

    def call(auto_create: false)
      ActiveRecord::Base.transaction do
        if (user = find(email))
          authorization.update!(user:)
          update(user)
          user
        elsif auto_create
          create
        else
          raise Error.new 'user_creation_required'
        end
      end
    end

    # Return email extracted from provider information.
    #
    # Used to lookup user from database.
    def email
      data[:email]
    end

    # A hash of attributes for new users extracted from the SSO payload.
    #
    # This *must* contain at least the keys "email" and "full_name".
    # Most likely, providers also want to set the "confirmed" flag.
    def data
      raise NotImplementedError
    end

    # Find user for given email address or return nil.
    def find(email)
      return if email.blank?

      record = Email.address(email).take

      return unless record
      raise Error.new 'email_taken' unless record.confirmed?

      record.user
    end

    # Called when an existing user is found for given
    # authorization. Can be used to e.g. update fields.
    def update(_user)
      # do nothing by default
    end

    # Called when no user for given authorization exists
    # and a new one should be created.
    def create
      User::Create.new(data).call.tap do |user|
        authorization.update!(user:)

        NotificationService::SendWelcomeEmailJob.perform_later(user.id, nil)
      end
    end

    def confirm_email(user)
      email = user.emails.address(data[:email]).first

      if email
        email.update! confirmed: true
      else
        user.emails.create! address: data[:email], confirmed: true
      end
    end
  end
end
end
