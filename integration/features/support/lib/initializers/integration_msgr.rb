# frozen_string_literal: true

if Rails.env.integration?
  XiIntegration.hook :test_setup do
    Msgr.client.start
  end

  XiIntegration.hook :test_teardown do
    Msgr.client.stop delete: true
    Msgr.client.start
  end
end
