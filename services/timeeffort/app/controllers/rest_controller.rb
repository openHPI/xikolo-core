# frozen_string_literal: true

class RESTController < ApplicationController
  module APIBehaviorFix
    def api_behavior
      raise MissingRenderer.new(format) unless has_renderer?

      location = {}

      if options[:location] != false && resource.respond_to?(:model)
        location[:location] = api_location
      end

      if get?
        display resource
      elsif post?
        display resource, location.merge(status: :created)
      elsif put? || patch?
        display resource, location.merge(status: :ok)
      elsif delete?
        display resource, status: :ok
      else
        head :no_content
      end
    end
  end

  responders APIBehaviorFix,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder

  # **** api responders ****

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
    @resource_name ||= controller_name.singularize.camelize
  end

  def self.resource_class
    @resource_class ||= ActiveSupport::Inflector.constantize resource_name
  end

  # paginate reponder methods

  def max_per_page
    100
  end

  def per_page
    params[:per_page].try(:to_i) || params[:limit].try(:to_i) || 50
  end

  def format
    params[:format]
  end
end
