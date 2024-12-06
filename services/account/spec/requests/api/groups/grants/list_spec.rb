# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Grants: Listing', type: :request do
  subject(:resource) { base.rel(:grants).get.value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:base) { api.rel(:group).get(id: group).value! }
  let(:group) { create(:group, name: 'owner.groupname') }
  let(:roles) { create_list(:role, 2) }
  let(:context) { create(:context) }
  let!(:grants) do
    [
      create(:grant, principal: group, role: roles[0], context: Context.root),
      create(:grant, principal: group, role: roles[1], context:),
    ]
  end

  before do
    create(:grant, principal: create(:group), role: roles[0], context: Context.root)
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with user records' do
    expect(resource).to match_array json(grants)
  end
end
