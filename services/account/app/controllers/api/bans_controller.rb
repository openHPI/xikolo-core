# frozen_string_literal: true

class API::BansController < API::RESTController
  respond_to :json

  def create
    respond_with User.resolve(params[:user_id]).tap(&:ban!)
  end
end
