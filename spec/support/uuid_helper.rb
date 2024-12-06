# frozen_string_literal: true

module UUIDHelper
  def short_uuid(id)
    UUID(id).to_param
  end
end

RSpec.configure do |config|
  config.include UUIDHelper
end
