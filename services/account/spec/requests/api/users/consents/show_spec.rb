# frozen_string_literal: true

require 'spec_helper'

describe 'Show user consents', type: :request do
  subject(:resource) { base.rel(:self).get.value! }

  let(:api) { Restify.new(account_service_url).get.value! }

  let(:base) do
    api
      .rel(:user).get({id: user}).value!
      .rel(:consents).get.value!.first
  end

  let!(:consent) { create(:'account_service/consent') }
  let(:user) { consent.user }
  let(:treatment) { consent.treatment }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'responds with consent resource' do
    expect(resource).to match \
      'name' => treatment.name,
      'required' => treatment.required,
      'consented' => true,
      'consented_at' => consent.consented_at.iso8601(0),
      'self_url' => account_service.user_consent_url(user, treatment)
  end
end
