# frozen_string_literal: true

class API::AuthorizationsController < API::RESTController
  respond_to :json

  has_scope :provider
  has_scope :uid
  has_scope :user

  rfc6570_params index: %i[provider uid user]

  def index
    respond_with collection
  end

  def show
    respond_with resource
  end

  # Create action first checks if an authentication with given
  # `provider` and `uid` exists. If a matching record is found
  # it will be updated with given information and returned.
  # Otherwise a new record will be created.
  #
  def create
    authentication = Authorization.find_by provider: params[:provider].to_s,
      uid: params[:uid].to_s
    if authentication
      authentication.update(authorization_params.to_h.compact)
    else
      authentication = Authorization.create authorization_params
    end

    respond_with authentication
  end

  def update
    resource.update authorization_params
    respond_with resource
  end

  def destroy
    resource.destroy
    respond_with resource
  end

  private

  def authorization_params
    params
      .permit(:provider, :uid, :user_id, :token, :secret, :expires_at)
      .tap do |whitelist|
        whitelist[:info] = params[:info].permit! if params.key?(:info)
      end
  end
end
