# frozen_string_literal: true

require 'spec_helper'

describe 'Users: Features: Delete', type: :request do
  subject(:resource) { base.rel(:features).delete({name: features[2].name}).value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:base) { api.rel(:user).get({id: user}).value! }
  let(:user) { create(:'account_service/user') }

  let!(:features) do
    [
      create_list(:'account_service/feature', 2),
      create_list(:'account_service/feature', 2, owner: user),
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
