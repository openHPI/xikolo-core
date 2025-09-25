# frozen_string_literal: true

require 'spec_helper'

describe Admin::Statistics::ClientUsage do
  it 'joins client types and keeps totals and relative values' do
    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, '/metrics')
      .to_return Stub.json([
        {'name' => 'client_combination_usage', 'available' => true},
      ])
    Stub.request(
      :learnanalytics, :get, '/metrics/client_combination_usage',
      query: hash_including({})
    ).to_return Stub.json([
      {'client_types' => %w[desktop_view mobile_view], 'total_users' => 42, 'relative_users' => 0.6},
    ])

    rows = described_class.call

    expect(rows.first).to include(
      'client_types' => 'Desktop View + Mobile View',
      'total_users' => 42,
      'relative_users' => '0.6%'
    )
  end
end
