# frozen_string_literal: true

require 'spec_helper'

describe 'CMI5: State', type: :request do
  let(:user) { create(:'account_service/user') }
  let(:item_id) { SecureRandom.uuid }
  let(:activity_id) { "https://example.test/cmi5/activities/#{item_id}" }
  let(:registration) { SecureRandom.uuid }
  let(:agent) do
    {
      objectType: 'Agent',
      account: {
        homePage: 'https://example.test',
        name: user.id,
      },
    }.to_json
  end
  let(:state_id) { 'test_state' }

  def encode_basic_credentials(token)
    Base64.strict_encode64("#{token}:")
  end

  def auth_token_for
    Cmi5::TokensController.verifier.generate(
      {item_id:},
      purpose: :cmi5_reporting,
      expires_in: 1.day
    )
  end

  def basic_auth_token
    encoded = encode_basic_credentials(auth_token_for)
    "Basic #{encoded}"
  end

  def invalid_auth_token
    # Generate a token with a different verifier secret so verification fails
    bad_verifier = ActiveSupport::MessageVerifier.new('different_secret')
    token = bad_verifier.generate({item_id: 'test'}, purpose: :cmi5_reporting)
    encoded = encode_basic_credentials(token)
    "Basic #{encoded}"
  end

  def state_params
    {activityId: activity_id, agent:, registration:, stateId: state_id}
  end

  def state_path
    "/cmi5/reportings/activities/state?#{state_params.to_query}"
  end

  describe 'GET #show' do
    before { sign_in(user:) }

    context 'with valid Basic auth token' do
      context 'when stateId is LMS.LaunchData' do
        let(:state_id) { 'LMS.LaunchData' }

        it 'returns launch data' do
          get state_path, headers: {'Authorization' => basic_auth_token}

          expect(response).to have_http_status(:ok)
          body = response.parsed_body
          expect(body).to have_key(:launchMode)
          expect(body).to have_key(:moveOn)
          expect(body).to have_key(:launchParameters)
          expect(body).to have_key(:masteryScore)
          expect(body).to have_key(:launchDate)
          expect(body).to have_key(:contextTemplate)
        end
      end

      context 'when the state does not exist' do
        it 'returns 404 Not Found' do
          get state_path, headers: {'Authorization' => basic_auth_token}

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when a state coordinate is missing' do
        it 'returns 400 Bad Request' do
          get '/cmi5/reportings/activities/state',
            params: state_params.except(:agent),
            headers: {'Authorization' => basic_auth_token}

          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'with invalid token' do
      it 'returns 401 Unauthorized' do
        get state_path, headers: {'Authorization' => invalid_auth_token}

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include('error' => 'Unauthorized')
      end
    end

    context 'with missing Authorization header' do
      it 'returns 401 Unauthorized' do
        get state_path

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include('error' => 'Unauthorized')
      end
    end

    context 'with malformed Authorization header' do
      it 'returns 401 Unauthorized' do
        get state_path, headers: {'Authorization' => 'NotAValidScheme'}

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include('error' => 'Unauthorized')
      end
    end
  end

  describe 'PUT #update' do
    before { sign_in(user:) }

    context 'with valid token' do
      it 'accepts state data' do
        put state_path,
          params: {score: 100},
          headers: {'Authorization' => basic_auth_token},
          as: :json

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context 'without an authenticated user' do
    it 'returns 401 Unauthorized' do
      get state_path, headers: {'Authorization' => basic_auth_token}

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include('error' => 'Unauthorized')
    end
  end
end
