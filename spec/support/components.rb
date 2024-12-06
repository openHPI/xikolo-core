# frozen_string_literal: true

require 'view_component/test_helpers'

# @deprecated Only used for testing "XUI components"
RSpec.shared_context 'component:view_context' do
  let(:view_context) do
    controller = ApplicationController.new
    controller.set_request! request
    controller.view_context
  end

  let(:request) { ActionDispatch::TestRequest.create }
end

RSpec.configure do |config|
  config.include_context 'component:view_context', type: :component
  config.include ViewComponent::TestHelpers, type: :component
end
