# frozen_string_literal: true

module AccountService
class API::PasswordResetsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def show
    respond_with resource
  end

  def create
    respond_with PasswordReset.create_by_email params[:email]
  end

  def update
    resource.errors.add :password, 'missing' if password.blank?
    resource.errors.add :base, 'expired' if resource.expired?

    if resource.errors.empty?
      ActiveRecord::Base.transaction do
        user = resource.user
        user.update! password:,
          password_confirmation: password

        user.password_resets.delete_all
      rescue ActiveRecord::RecordInvalid => e
        e.record.errors.each do |err|
          resource.errors.add(err.attribute, err.message)
        end
      end
    end

    respond_with resource
  end

  def find_resource
    scoped_resource.where(token: params[:id]).take!
  end

  def password
    params[:password]
  end
end
end
