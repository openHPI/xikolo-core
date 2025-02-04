# frozen_string_literal: true

module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end
end

RSpec.configure do |config|
  config.include Requests::JsonHelpers
end
