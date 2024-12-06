# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '[API v2] Course: List: Limit access to groups', type: :request do
  subject(:resource) { api.rel(:courses).get.value }

  let(:api)     { Restify.new(:api, headers:).get.value }
  let(:group)   { 'xikolo.test.affiliated' }
  let(:headers) { session_request_headers session }
  let(:user_id) { generate(:user_id) }

  let(:session) do
    setup_session user_id, features: {'course.access-group': 'true'}
  end

  let!(:courses) do
    [
      create(:course, status: 'active'),
      create(:course, status: 'active', groups: [group]),
    ]
  end

  let(:user_groups) { [] }

  before do
    Stub.request(
      :account, :get, '/groups', query: {user: user_id, per_page: 1000}
    ).to_return Stub.json(user_groups)
  end

  context 'with user w/o group membership' do
    it 'lists only non-restricted courses' do
      expect(resource.map(&:id)).to contain_exactly(courses.first.id)
    end
  end

  context 'with user w/ group membership' do
    let(:user_groups) do
      [
        {'name' => 'xikolo.test.some.group'},
        {'name' => group},
      ]
    end

    it 'lists all courses' do
      expect(resource.map(&:id)).to match_array courses.map(&:id)
    end
  end
end
