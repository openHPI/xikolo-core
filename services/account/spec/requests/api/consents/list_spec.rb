# frozen_string_literal: true

require 'spec_helper'

describe 'List consents', type: :request do
  subject(:resource) { user_resource.rel(:consents).get.value! }

  let(:api) { Restify.new(account_service_url).get.value! }
  let(:user_resource) { api.rel(:user).get({id: user.id}).value! }
  let(:user) { create(:'account_service/user') }
  let!(:consents) { create_list(:'account_service/consent', 2, user:) }

  it { is_expected.to respond_with :ok }

  it 'responds with a list of consents' do
    expect(resource).to contain_exactly(
      hash_including(
        'name' => consents[0].treatment.name,
        'required' => false,
        'consented' => true
      ), hash_including(
        'name' => consents[1].treatment.name,
        'required' => false,
        'consented' => true
      )
    )
  end

  context 'with external consent' do
    let(:treatment) { create(:'account_service/treatment', :external, name: 'external_treatment') }

    before { create(:'account_service/consent', user:, treatment:) }

    it 'has an external consent url' do
      expect(resource).to include hash_including(
        'name' => 'external_treatment',
        'external_consent_url' => 'https://example.com/consents'
      )
    end
  end
end
