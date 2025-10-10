# frozen_string_literal: true

module AccountService
class API::GrantsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  has_scope :role do |_, scope, value|
    scope.where(role: Role.resolve(value))
  end

  has_scope :context do |_, scope, value|
    scope.where(context: Context.resolve(value))
  end

  # @url /grants
  # @action GET
  #
  # List (filtered) grants.
  #
  # @response [Grant] Collection of grant resources.
  #
  rfc6570_params index: %i[role context]
  def index
    respond_with collection
  end

  # @url /grants
  # @action POST
  #
  # Create new grant record.
  #
  # TODO: Parameter description and constrains
  #
  # @response [Grant] Created grant record.
  #
  def create
    grant = Grant.find_or_initialize_by grant_params
    if grant.new_record?
      grant.save
      respond_with grant
    else
      respond_with grant, status: :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_with e.record
  end

  # @url /grants/{id}
  # @action GET
  #
  # Get a specific grant
  #
  # @response [Grant] Single grant resource.
  #
  def show
    respond_with resource
  end

  # @url /grants/{id}
  # @action DELETE
  #
  # Delete a specific grant
  #
  # @response [Grant] Deleted grant resource.
  #
  def destroy
    respond_with resource.destroy
  rescue ActiveRecord::RecordNotFound
    head :no_content
  end

  private

  def grant_params
    {context:, role:, principal: group}
  end

  def group
    Group.resolve params.require(:group)
  end

  def context
    Context.resolve params.require(:context)
  end

  def role
    Role.resolve params.require(:role)
  end
end
end
