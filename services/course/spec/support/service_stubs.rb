# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Stub.service(:account, build(:'account:root'))
  end
end
