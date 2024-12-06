# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UserTestsController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { %w[grouping.user_test.index grouping.user_test.export grouping.user_test.manage] }
  let(:user_test_id) { SecureRandom.uuid }
  let(:course_id) { '00000001-3300-4444-9999-000000000002' }
  let(:user_test) do
    {
      id: user_test_id,
      name: 'Pink background',
      identifier: 'pink_background',
      description: 'Show pink background',
      start_date: '2015-03-08T17:48:16.136Z',
      end_date: '2015-03-15T17:48:16.136Z',
      max_participants: nil,
      course_id:,
      metric_ids: [
        '223112c8-2da6-4e90-8f83-f1b26f1accfc',
      ],
      created_at: '2015-03-10T17:48:16.246Z',
      updated_at: '2015-03-10T17:48:16.246Z',
      total_count: 399,
      finished_count: 399,
      waiting_count: nil,
      finished: true,
      mean: {
        '223112c8-2da6-4e90-8f83-f1b26f1accfc' => 0.566416040100251,
      },
      test_groups_url: "/test_groups?user_test_id=#{user_test_id}",
      metrics_url: "/metrics?user_test_id=#{user_test_id}",
      filters_url: "/filters?user_test_id=#{user_test_id}",
    }
  end

  before do
    xi_config <<~YML
      beta_features:
        show_user_tests: true
    YML

    stub_user(id: user_id, display_name: 'John Smith', permissions:)

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      title: 'A Course',
      course_code: 'somecode',
    })

    Stub.service(
      :grouping,
      user_tests_url: '/user_tests',
      user_test_url: '/user_tests/{id}'
    )
  end

  describe 'GET index' do
    before do
      Stub.request(
        :grouping, :get, '/user_tests'
      ).to_return Stub.json([user_test])
    end

    it 'answers with a page' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET show' do
    before do
      Stub.request(
        :grouping, :get, "/user_tests/#{user_test_id}",
        query: {export: 'false', statistics: 'true'}
      ).to_return Stub.json(user_test)

      Stub.request(
        :grouping, :get, '/test_groups',
        query: {user_test_id:}
      ).to_return Stub.json([])

      Stub.request(
        :grouping, :get, '/metrics',
        query: {user_test_id:}
      ).to_return Stub.json([])

      Stub.request(
        :grouping, :get, '/filters',
        query: {user_test_id:}
      ).to_return Stub.json([])
    end

    it 'answers with a page' do
      get :show, params: {id: user_test_id}
      expect(response).to have_http_status :ok
    end
  end
end
