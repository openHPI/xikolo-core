# frozen_string_literal: true

class API::PoliciesController < API::RESTController
  respond_to :json

  def index
    respond_with Policy.all
  end

  def create
    respond_with Policy.create policy_params
  end

  private

  def policy_params
    params.permit :version, url: params[:url].keys
  end
end
