# frozen_string_literal: true

module AccountService
class API::GroupsController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  has_scope :user do |_, scope, value|
    scope.joins(:memberships).where(memberships: {user_id: value})
  end

  has_scope :tag do |_, scope, value|
    scope.where('? = ANY(tags)', value)
  end

  has_scope :prefix

  rfc6570_params index: %i[user tag prefix]
  def index
    respond_with collection
  end

  def create(attributes = group_params)
    respond_with Group.create(attributes), status: :created
  end

  def show
    respond_with resource
  end

  def grants
    respond_with resource.grants
  end

  # @url /groups/{id}
  # @action PATCH
  #
  # Update group record.
  #
  # @param id [String|UUID] Identify group by id or by name
  #
  # @response [Group] Updated/created group record.
  #
  def update
    resource.update group_params
    respond_with resource
  rescue ActiveRecord::RecordNotFound
    raise unless request.method == 'PUT'

    create group_params.merge extra_group_params
  end

  def destroy
    resource.destroy!

    respond_with resource
  end

  private

  def resource_id
    params.fetch(:id) { params.fetch(:group_id) }
  end

  def group_params
    params.permit :name, :description, :tag
  end

  def extra_group_params
    if (uuid = UUID4.try_convert(params[:id].to_s))
      {id: uuid.to_s}
    else
      {name: params[:id].to_s}
    end
  end
end
end
