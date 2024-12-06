# frozen_string_literal: true

class User::Create < ApplicationOperation
  include Facets::Transaction
  include Facets::Tracing

  attr_reader :params

  def initialize(params)
    super()

    @params = params
  end

  def call
    user = User.create! \
      params.except(:email, :confirmed, :admin)

    begin
      user.emails.create! \
        address: params.fetch(:email, ''),
        confirmed: params.fetch(:confirmed, false),
        primary: true,
        force: true
    rescue ActiveRecord::RecordInvalid => e
      # It's not a Hash but ActionModel::Errors
      e.record.errors.each {|err| user.errors.add(:email, err.message) }

      raise ActiveRecord::RecordInvalid.new user
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    user.adminize! if params[:admin]
    user.update_profile_completion!

    user
  end
end
