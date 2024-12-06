# frozen_string_literal: true

class API::PermissionsController < API::RESTController
  respond_to :json

  rfc6570_params index: %i[context user_id]

  def index
    render json: permissions
  end

  private

  def permissions
    Role.permissions(principal:, context:)
  end

  def context
    if params[:context].present?
      Context.resolve params[:context]
    else
      Context.root
    end
  end

  def principal
    User.find params[:user_id]
  end
end
