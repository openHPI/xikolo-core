# frozen_string_literal: true

require 'spec_helper'

describe 'CMI5: Reportings', type: :request do
  let(:user) { create(:'account_service/user') }
  let(:item_id) { SecureRandom.uuid }
  let(:token) { auth_token_for(item_id) }
  let(:headers) { basic_auth_header(token) }

  def auth_token_for(item_id)
    Cmi5::ReportingsController.verifier.generate(
      {item_id:},
      purpose: :cmi5_reporting,
      expires_in: 1.day
    )
  end

  def basic_auth_header(token)
    encoded = Base64.strict_encode64("#{token}:")
    {'Authorization' => "Basic #{encoded}"}
  end

  def invalid_auth_header
    bad_verifier = ActiveSupport::MessageVerifier.new('different_secret')
    token = bad_verifier.generate({item_id: 'test'}, purpose: :cmi5_reporting)
    basic_auth_header(token)
  end

  before { sign_in user: }

  describe 'PUT /statements' do
    let(:statement_id) { SecureRandom.uuid }
    let(:statement) { {id: statement_id} }

    it 'accepts a single identified statement' do
      put statement_path,
        params: statement,
        headers:,
        as: :json

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it 'rejects a request without statementId' do
      put '/cmi5/reportings/statements',
        params: statement,
        headers:,
        as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects a statement whose ID differs from statementId' do
      put "/cmi5/reportings/statements?statementId=#{SecureRandom.uuid}",
        params: statement,
        headers:,
        as: :json

      expect(response).to have_http_status(:bad_request)
    end

    def statement_path
      "/cmi5/reportings/statements?statementId=#{statement_id}"
    end
  end

  describe 'POST /statements' do
    let(:statement_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

    it 'returns the ID of a single statement' do
      post '/cmi5/reportings/statements',
        params: {id: statement_ids.first},
        headers:,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([statement_ids.first])
    end

    it 'returns the IDs of a statement batch in order' do
      post '/cmi5/reportings/statements',
        params: statement_ids.map {|id| {id:} },
        headers:,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(statement_ids)
    end

    it 'rejects statements without an ID' do
      post '/cmi5/reportings/statements', params: {verb: {}}, headers:, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an empty batch' do
      post '/cmi5/reportings/statements', params: [], headers:, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET /activities' do
    let(:activity_id) { "https://example.test/cmi5/activities/#{item_id}" }

    it 'returns the requested Activity' do
      get '/cmi5/reportings/activities',
        params: {activityId: activity_id},
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'objectType' => 'Activity',
        'id' => activity_id
      )
    end

    it 'rejects a request without activityId' do
      get '/cmi5/reportings/activities', headers: headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'authentication' do
    it 'rejects a missing token' do
      post '/cmi5/reportings/statements', params: {id: SecureRandom.uuid}, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects an invalid token' do
      post '/cmi5/reportings/statements',
        params: {id: SecureRandom.uuid},
        headers: invalid_auth_header,
        as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include('error' => 'Unauthorized')
    end

    it 'rejects an expired token' do
      expired_token = Cmi5::ReportingsController.verifier.generate(
        {item_id: 'expired'},
        purpose: :cmi5_reporting,
        expires_in: -1.second
      )

      post '/cmi5/reportings/statements',
        params: {id: SecureRandom.uuid},
        headers: basic_auth_header(expired_token),
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a token without an item ID' do
      token_without_item = Cmi5::ReportingsController.verifier.generate(
        {},
        purpose: :cmi5_reporting,
        expires_in: 1.day
      )

      post '/cmi5/reportings/statements',
        params: {id: SecureRandom.uuid},
        headers: basic_auth_header(token_without_item),
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
