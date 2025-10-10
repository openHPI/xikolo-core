# frozen_string_literal: true

module AccountService
class API::EmailsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def index
    respond_with collection
  end

  def show
    respond_with resource
  end

  def update
    resource.update params.permit(:confirmed, :primary, :force)
    respond_with resource.user, resource
  end

  def replace
    emails = User::ReplaceEmails.new(user, replace_params).call
    respond_with emails, location: false
  rescue User::ReplaceEmails::OperationError
    error_invalid
  end

  def create
    email = user.emails.create(params.permit(:address, :confirmed))
    email.reload if email.persisted?
    respond_with user, email
  end

  def destroy
    resource.destroy if resource.destroyable?
    respond_with resource
  end

  private

  def user
    User.find params[:user_id]
  end

  # ActionDispatch::Http:Parameters by default assigns parsed params to a _json key,
  # if these do not result in a hash.
  # We therefore need to use the _json key to access the array containing the hash of the mail params.
  def replace_params
    params.permit(_json: %i[address confirmed primary]).fetch(:_json, [])
  end

  def default_scope(emails)
    if request.path_parameters.key?(:user_id)
      emails.where(user_id: request.path_parameters[:user_id])
    else
      emails
    end
  end

  def find_resource
    if (uuid = UUID4.try_convert(identifier))
      scoped_resource.find_by!(uuid:)
    else
      scoped_resource.address(identifier).take!
    end
  end

  def identifier
    request.path_parameters[:id]
  end
end
end
