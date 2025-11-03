# frozen_string_literal: true

# @restful_api 1
#
module AccountService
class API::UsersController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  has_scope :query
  has_scope :search
  has_scope :auth_uid

  has_scope :archived, default: 'false', allow_blank: true do |_, scope, value|
    case value
      when 'true'    then scope.where(archived: true)
      when 'include' then scope
      else scope.where(archived: false)
    end
  end

  has_scope :confirmed do |_, scope, value|
    case value
      when 'true'  then scope.confirmed
      when 'false' then scope.unconfirmed
      else scope
    end
  end

  has_scope :id do |_, scope, value|
    scope.by_id value.split(',').map {|u| UUID u }.map(&:to_s)
  end

  has_scope :permission do |controller, scope, value|
    context = controller.params.fetch(:context, Context.root)
    scope.with_permission(value, context:)
  end

  # @url /users{?search,query,archived,confirmed,id}
  # @action GET
  #
  # Get a list of users.
  #
  # This endpoint is paginated. By default only 50 records
  # will be returned. Use provided links to navigation pages.
  #
  # @optional search [String] Search for users by name
  #   or email if they are enabled to be found by searching.
  #   Allows for partial match in first name, last name and
  #   display name, but only for exact match in email addresses.
  # @optional query [String] Search for users by name or email
  #   independently of any account settings. Also allow for
  #   partial match in email address.
  # @optional archived [String] Restrict returned users to
  #   either being archived or being not archived by setting
  #   `archived` to 'true' or 'false'. Set it to 'include' to
  #   return all users being archived or not. Defaults to 'false'.
  # @optional confirmed [Boolean] Set to true to only return
  #   confirmed users. Set to false to only return unconfirmed
  #   user. When not specified all users will be returned. By
  #   default is unspecified.
  # @optional id [UUID, Array<UUID>] Restrict returned users
  #   to list of with UUIDs in given set. Can be a single UUID
  #   or a comma-separated list of UUIDs.
  # @optional permission [String] Filter users for given permission.
  #   Only uses having the permission by a user or group grant will
  #   be returned.
  # @optional context [String] Apply a context scope to filters
  #   supporting a scope lookup like `permissions=`.
  # @optional auth_uid [String] Search for users by authorization uid.
  #
  # @response [Array<User>] List of users.
  #
  rfc6570_params \
    index: %i[search query archived confirmed id permission context auth_uid]
  def index
    respond_with collection
  end

  # @url /users/{id}
  # @action GET
  #
  # Get a specific user by UUID.
  #
  # @response [User] Single user resource.
  #
  def show
    response.headers['X-Cache-Xikolo'] = 'shared'
    response.link user_emails_url(resource.id), rel: :emails

    respond_with resource
  end

  # @url /users
  # @action POST
  #
  # Create new user record.
  #
  # TODO: Parameter description and constrains
  #
  # @response [User] Created user record.
  #
  def create(attrs = {})
    attributes = user_params.merge(attrs)
    attributes[:confirmed] = params[:confirmed]

    user = User::Create.new(attributes).call

    respond_with user
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  # @url /users/{id}
  # @action PATCH
  #
  # Update user record.
  #
  # Note: Email is read-only and cannot be changed. A changed email
  # address will result in a `400 Bad Request` response.
  #
  # TODO: Parameter description and constrains
  #
  # @response [User] Updated user record.
  #
  def update
    if user_params.key?(:email) && resource.email != user_params[:email]
      render status: :bad_request,
        json: {errors: {email: ['read-only']}}
      return
    end

    respond_with User::Update.new(resource, user_params).call
  rescue ActiveRecord::RecordNotFound
    raise unless request.method == 'PUT'

    create id: params[:id]
  end

  # @url /users/{id}
  # @action DELETE
  #
  # Delete user record.
  #
  # The user record will not be completely removed but just
  # archived and anonymized. Email addresses will deleted and
  # user names will be replaced with placeholders. Profile
  # fields are preserved unchanged.
  #
  # @response [User] Anonymized user record.
  #
  def destroy
    respond_with User::Destroy.call(resource)
  end

  def default_scope(scope)
    scope.where(anonymous: false).with_embedded_resources
  end

  def pagination_adapter_init(responder)
    return unless responder.resource.respond_to?(:paginate)

    Paginator.new responder, :created_at
  end

  private

  def user_params
    params.permit %i[
      accepted_policy_version
      affiliated
      avatar_upload_id
      avatar_uri
      born_at
      display_name
      email
      full_name
      language
      password
      password_digest
      gender
      status
      country
      state
      city
    ]
  end
end
end
