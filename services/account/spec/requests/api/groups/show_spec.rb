# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Show', type: :request do
  subject(:resource) { api.rel(:group).get({id: 'owner.groupname'}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:group) { create(:group, name: 'owner.groupname') }

  it 'responds with group resource' do
    expect(resource).to eq json(group)
  end

  it 'links to group members' do
    expect(resource.rel(:members)).to eq group_members_url(group)
  end

  it 'links to stats resources' do
    expect(resource).to have_rel :stats
    expect(resource).to have_rel :profile_field_stats
  end
end
