# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    # Reset the config after every test case so that modifying the config for one scenario
    # does not affect following scenarios (which can lead to nasty order dependencies).
    Xikolo::Config.reload
  end
end
