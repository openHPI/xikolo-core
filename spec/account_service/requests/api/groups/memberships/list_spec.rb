# frozen_string_literal: true

require 'spec_helper'

describe 'Group Memberships: List', type: :request do
  subject(:resource) { api.rel(:memberships).get(params).value! }

  let(:api) do
    Restify.new(account_service_url).get.value!.rel(:group).get({id: group.to_param}).value!
  end

  let(:params) { {group_id: group.to_param} }
  let(:group) { create(:'account_service/group') }

  let!(:memberships) do
    create_list(:'account_service/membership', 5, group:)
  end

  before do
    # create some other memberships for different groups
    create_list(:'account_service/membership', 5)
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with membership resource' do
    expect(resource).to eq json(memberships)
  end
end
