# frozen_string_literal: true

module AccountService
class API::RESTController < API::BaseController # rubocop:disable Layout/IndentationWidth
  self.responder = Responders::API

  include HasScope

  def resource
    @resource ||= find_resource
  end

  def collection
    @collection ||= find_collection
  end

  def default_scope(scope)
    scope
  end

  def scoped_resource
    default_scope self.class.resource_class.all
  end

  def find_resource
    scope = scoped_resource
    if scope.respond_to? :resolve
      scoped_resource.resolve resource_id
    else
      scoped_resource.find resource_id
    end
  end

  def resource_id
    params[:id]
  end

  def find_collection
    apply_scopes default_scope self.class.resource_class.all
  end

  def self.resource_name
    @resource_name ||= "AccountService::#{controller_name.singularize.camelize}"
  end

  def self.resource_class
    @resource_class ||= ActiveSupport::Inflector.constantize resource_name
  end

  # paginate responder methods

  def max_per_page
    500
  end

  def default_per_page
    50
  end

  def per_page
    params[:per_page].try(:to_i) || params[:limit].try(:to_i) || default_per_page
  end

  def format
    params[:format]
  end
end
end
