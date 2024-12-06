# frozen_string_literal: true

class API::MembershipsController < API::RESTController
  respond_to :json

  # This comes from the path parameter from the `groups/:group_id/memberships`
  # route.
  has_scope :group_id do |_, scope, value|
    scope.where(group: Group.resolve(value.to_s))
  end

  def index
    respond_with collection
  end

  def create
    begin
      membership = Membership.find_or_create_by!(user:, group:)
    rescue ActiveRecord::RecordNotUnique
      retry
    rescue ActiveRecord::RecordNotFound
      membership ||= Membership.new
      membership.errors.add :user, 'required'
    rescue ActiveRecord::RecordInvalid => e
      membership ||= Membership.new
      e.record.errors[:name].each do |item|
        membership.errors.add :group, item
      end
    end

    respond_with membership
  end

  def show
    respond_with resource
  end

  def destroy
    respond_with resource.destroy
  rescue ActiveRecord::RecordNotFound
    head :no_content
  end

  def delete
    ActiveRecord::Base.transaction do
      user  = User.resolve params[:user]
      group = Group.resolve params[:group]

      respond_with Draper::CollectionDecorator.new \
        Membership.where(user:, group:).map(&:destroy)
    end
  end

  def max_per_page
    10_000
  end

  def default_per_page
    5_000
  end

  private

  def group
    Group.resolve params[:group]
  rescue ActiveRecord::RecordNotFound
    Group.create! name: params[:group]
  end

  def user
    User.resolve params[:user]
  end
end
