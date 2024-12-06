# frozen_string_literal: true

class API::RolesController < API::RESTController
  respond_to :json

  def index
    respond_with Role.all
  end

  # @url /roles
  # @action POST
  #
  # Create new role record.
  #
  # TODO: Parameter description and constrains
  #
  # @response [Role] Created role record.
  #
  def create(params = role_params)
    respond_with Role.create(params), status: :created
  end

  # @url /roles/{id}
  # @action GET
  #
  # Get a specific role by UUID or by name.
  #
  # @response [Role] Single role resource.
  #
  def show
    respond_with resource
  end

  # @url /roles/{id}
  # @action PATCH
  #
  # Update role record.
  #
  # @param id [String|UUID] Identify role by id or by name
  #
  # @response [Role] Updated/created role record.
  #
  def update
    resource.update role_params
    respond_with resource
  rescue ActiveRecord::RecordNotFound
    raise unless request.method == 'PUT'

    create role_params.merge extra_role_params
  end

  private

  def role_params
    params.permit(:name, permissions: [])
  end

  def extra_role_params
    if (uuid = UUID4.try_convert(params[:id].to_s))
      {id: uuid.to_s}
    else
      {name: params[:id].to_s}
    end
  end
end
