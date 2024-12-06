# frozen_string_literal: true

require 'spec_helper'

describe 'Statistics: Ticket Stats', type: :request do
  include Rack::Test::Methods

  def app
    Xikolo::API
  end

  subject(:response) { get '/v2/statistics/platform_dashboard/tickets.json', nil, env_hash }

  let(:user_id) { generate(:user_id) }
  let(:env_hash) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'rack.session' => {id: stub_session_id},
    }
  end

  before do
    create_list(:ticket, 3)
    api_stub_user id: user_id, permissions: %w[global.dashboard.show]
  end

  it 'renders a json response with ticket stats' do
    expect(JSON.parse(response.body)).to match(
      'ticket_count' => 3,
      'ticket_count_last_day' => 0,
      'avg_tickets_per_day_last_year' => a_value_within(0.0001).of(0.0082)
    )
  end
end
