# frozen_string_literal: true

module AccountService
class API::BansController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def create
    respond_with User.resolve(params[:user_id]).tap(&:ban!)
  end
end
end
