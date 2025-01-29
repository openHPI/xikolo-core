# frozen_string_literal: true

class API::SessionsController < API::RESTController
  respond_to :json

  has_scope :user_id do |_, scope, value|
    scope.where user_id: value
  end

  rfc6570_params index: [:user_id]

  def index
    respond_with collection
  end

  rfc6570_params show: %i[embed context]

  def show
    expires_in 1.minute, public: true if resource.anonymous?

    session = resource
    session.access!

    respond_with session, embed:, context: -> { context }
  end

  def create
    if handler.authenticated?
      respond_with handler.session
    else
      render status: :unprocessable_content, json: {errors: handler.errors}
    end
  end

  def destroy
    respond_with resource.destroy!
  end

  private

  def handler
    @handler ||= AuthenticationHandler.new session_params
  end

  def context
    if params['context'].present?
      Context.resolve params['context']
    else
      Context.root
    end
  end

  def embed
    params[:embed].to_s.split(',').map(&:strip)
  end

  def session_params
    params.permit :ident, :password, :authorization, :user, :user_agent,
      :autocreate
  end
end
