# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root', type: :request do
  let(:root) do
    {
      items_url: timeeffort_service.items_rfc6570,
      item_url: timeeffort_service.item_rfc6570,
      item_overwritten_time_effort_url: timeeffort_service.item_overwritten_time_effort_rfc6570,
    }.as_json
  end

  it 'returns root resource on /' do
    expect(restify_with_headers('http://test.host/timeeffort_service').get.value!).to eq root
  end
end
