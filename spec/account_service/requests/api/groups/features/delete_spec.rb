# frozen_string_literal: true

require 'spec_helper'

describe 'Groups: Features: Delete', type: :request do
  subject(:resource) { base.rel(:features).delete({name: features[2].name}).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:base) { api.rel(:group).get({id: group}).value! }
  let(:group) { create(:'account_service/group') }

  let!(:features) do
    [
      create_list(:'account_service/feature', 2),
      create_list(:'account_service/feature', 2, owner: group),
      create_list(:'account_service/feature', 2),
    ].flatten
  end

  it 'responds with 204 No Content' do
    expect(resource).to respond_with :no_content
  end

  it 'removes feature record' do
    expect { resource }.to change {
      AccountService::Feature.exists?(features[2].id)
    }.from(true).to(false)
  end
end
