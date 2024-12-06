# frozen_string_literal: true

class API::EmailSuspensionsController < API::RESTController
  respond_to :json

  def create
    response.headers['Content-Location'] =
      user_email_url user_id: resource.user_id, id: resource.uuid

    if resource.suspend!
      respond_with nil, status: :created, location: nil
    else
      respond_with nil, status: :ok, location: nil
    end
  end

  def destroy
    resource.unsuspend!

    render status: :ok, json: {msg: 'e-mail address unsuspended'}
  end

  private

  def find_resource
    if (uuid = UUID4.try_convert(identifier))
      scoped_resource.find_by!(uuid:)
    else
      scoped_resource.find_by! address: identifier
    end
  end

  def identifier
    request.path_parameters[:email_id] ||
      request.path_parameters[:address]
  end

  class << self
    def resource_class
      Email
    end
  end
end
