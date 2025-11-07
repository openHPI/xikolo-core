# frozen_string_literal: true

module JSONHelper
  def json(resource)
    resource = resource.decorate.as_json if resource.respond_to? :decorate

    case resource
      when Array
        resource.map {|r| json(r) }
      when Hash
        resource.stringify_keys
    end.as_json
  end
end

RSpec.configure do |config|
  config.include JSONHelper
end
