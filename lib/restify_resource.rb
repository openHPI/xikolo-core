# frozen_string_literal: true

class RestifyResource
  attr_reader :resource
  attr_accessor :model_name

  def initialize(resource: OpenStruct.new, params: {})
    @resource = resource
    params&.each_pair do |attribute, value|
      send :"#{attribute}=", value
    end
  end

  def persisted?
    resource['id'].present?
  end

  def method_missing(method, *, **)
    # OpenStruct does not `#respond_to?` any possible accessor but accepts them
    # nevertheless. Technically it should do that.
    if resource.is_a?(OpenStruct) || resource.respond_to?(method)
      resource.__send__(method, *, **)
    else
      super
    end
  end

  def respond_to_missing?(method, *)
    resource.respond_to?(method)
  end

  def to_model
    self
  end

  def deleted?
    response.code == 204
  end
end
