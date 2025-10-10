# frozen_string_literal: true

module AccountService
class API::PoliciesController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def index
    respond_with Policy.all
  end

  def create
    respond_with Policy.create(policy_params), location: nil
  end

  private

  def policy_params
    params.permit :version, url: params[:url].keys
  end
end
end
