# frozen_string_literal: true

require 'spec_helper'

describe 'List consents', type: :request do
  subject(:resource) { user_resource.rel(:consents).get.value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:user_resource) { api.rel(:user).get({id: user.id}).value! }
  let(:user) { create(:user) }
  let!(:consents) { create_list(:consent, 2, user:) }

  it { is_expected.to respond_with :ok }

  it 'responds with a list of consents' do
    expect(resource).to contain_exactly(an_object_having_attributes(
      'name' => consents[0].treatment.name,
      'required' => false,
      'consented' => true
    ), an_object_having_attributes(
      'name' => consents[1].treatment.name,
      'required' => false,
      'consented' => true
    ))
  end

  context 'with external consent' do
    let(:treatment) { create(:treatment, :external, name: 'external_treatment') }

    before { create(:consent, user:, treatment:) }

    it 'has an external consent url' do
      expect(resource).to include an_object_having_attributes(
        name: 'external_treatment',
        external_consent_url: 'https://example.com/consents'
      )
    end
  end
end
