# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Grants: Listing', type: :request do
  subject(:resource) { base.rel(:grants).get.value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }
  let(:group) { create(:'account_service/group', name: 'owner.groupname') }
  let(:roles) { create_list(:'account_service/role', 2) }
  let(:context) { create(:'account_service/context') }
  let!(:grants) do
    [
      create(:'account_service/grant', principal: group, role: roles[0], context: AccountService::Context.root),
      create(:'account_service/grant', principal: group, role: roles[1], context:),
    ]
  end

  before do
    create(:'account_service/grant', principal: create(:'account_service/group'), role: roles[0], context: AccountService::Context.root)
  end

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with user records' do
    expect(resource).to match_array json(grants)
  end
end
