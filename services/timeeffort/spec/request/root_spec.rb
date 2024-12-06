# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Root', type: :request do
  let(:root) do
    {
      items_url: items_rfc6570,
      item_url: item_rfc6570,
      item_overwritten_time_effort_url: item_overwritten_time_effort_rfc6570,
    }.as_json
  end

  it 'returns root resource on /' do
    expect(Restify.new('http://test.host').get.value!).to eq root
  end
end
