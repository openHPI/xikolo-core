# frozen_string_literal: true

module AccountService
class API::GroupMembersController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def index
    respond_with resource.members.with_embedded_resources
  end

  def pagination_adapter_init(responder)
    return unless responder.resource.respond_to?(:paginate)

    Xikolo::Paginator.new responder, :created_at
  end

  def per_page
    params.fetch(:per_page, 1000).to_i
  end

  def max_per_page
    2500
  end

  private

  def resource_id
    params[:group_id]
  end

  class << self
    def resource_class
      Group
    end
  end
end
end
