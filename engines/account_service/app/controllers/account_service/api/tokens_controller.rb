# frozen_string_literal: true

module AccountService
class API::TokensController < API::RESTController # rubocop:disable Layout/IndentationWidth
  respond_to :json

  def create
    token = Token.find_or_create_by(params.permit(:user_id))
    respond_with token
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def default_scope(tokens)
    tokens.where(token: params[:token])
  end

  def show
    respond_with token
  end

  rfc6570_params index: [:token]
  def index
    respond_with collection
  end

  private

  def token
    Token.find params[:id]
  end
end
end
