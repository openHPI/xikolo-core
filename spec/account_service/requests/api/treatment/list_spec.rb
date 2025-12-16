# frozen_string_literal: true

require 'spec_helper'

describe 'List treatments', type: :request do
  subject(:resource) { api.rel(:treatments).get(params).value! }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:params) { {} }

  let!(:treatments) do
    create_list(:'account_service/treatment', 3).each_with_index do |treatment, i|
      treatment.update!(required: i.even?)
    end
  end

  it { is_expected.to respond_with :ok }

  it 'responds with list of consents' do
    expect(resource).to contain_exactly(
      hash_including(
        'name' => treatments[0].name,
        'required' => true,
        'self_url' => account_service.treatment_url(treatments[0]),
        'consent_manager' => {}
      ), hash_including(
        'name' => treatments[2].name,
        'required' => true,
        'self_url' => account_service.treatment_url(treatments[2]),
        'consent_manager' => {}
      ), hash_including(
        'name' => treatments[1].name,
        'required' => false,
        'self_url' => account_service.treatment_url(treatments[1]),
        'consent_manager' => {}
      )
    )
  end

  context 'with external consent manager' do
    before { create(:'account_service/treatment', :external, name: 'external_treatment') }

    it 'contains treatment with external consent manager data' do
      expect(resource).to include hash_including(
        'name' => 'external_treatment',
        'consent_manager' => hash_including(
          'type' => 'external',
          'consent_url' => 'https://example.com/consents'
        )
      )
    end
  end
end
