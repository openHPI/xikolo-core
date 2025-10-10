# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Stub.service(:account, build(:'account:root'))

    Stub.service(:course, build(:'course:root'))
  end
end
