# frozen_string_literal: true

require 'spec_helper'

describe 'EmailSuspensions: Create', type: :request do
  subject(:resource) do
    api
      .rel(:email_suspensions)
      .post({}, params: {address: 'p.3/-k+fuu@example.de'})
      .value!
  end

  let(:user_id) { SecureRandom.uuid }
  let!(:user)   { create(:'account_service/user', id: user_id) }
  let!(:email)  { create(:'account_service/email', user:, address: 'p.3/-k+fuu@example.de') }
  let(:api)     { Restify.new(account_service_url).get.value! }

  it 'responds with a created status' do
    expect(resource).to respond_with :created
  end

  it 'suspends the email address' do
    expect { resource }.to change {
      AccountService::Feature
        .where(owner_id: user_id, name: 'primary_email_suspended')
        .count
    }.from(0).to(1)
  end

  it 'returns an empty response' do
    expect(resource.response.body).to eq 'null'

    # `resource` actually isn't a Nil object, but a
    # `Restify::Resource(nil)` that at least compares truthly to `nil`.
    #
    # rubocop:disable RSpec/BeEq
    expect(resource).to eq nil
    # rubocop:enable RSpec/BeEq
  end

  it 'returns email resource url in Content-Location header' do
    expect(resource).to include_header \
      'Content-Location' => account_service.user_email_url(user_id:, id: email.uuid)
  end

  context 'already suspended user' do
    before do
      email.suspend!
    end

    it 'responds with 200 Ok' do
      expect(resource).to respond_with :ok
    end

    it 'responds with Content-Location header' do
      expect(resource).to include_header \
        'Content-Location' => account_service.user_email_url(user_id:, id: email.uuid)
    end
  end

  context 'non-existent email address' do
    subject(:resource) do
      api
        .rel(:email_suspensions)
        .post({}, params: {address: 'justinbieber@example.de'})
        .value!
    end

    it 'responds with an error code' do
      expect { resource }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end
end
