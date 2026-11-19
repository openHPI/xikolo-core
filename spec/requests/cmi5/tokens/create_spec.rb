# frozen_string_literal: true

require 'spec_helper'

describe 'CMI5: Tokens: Create', type: :request do
  def decode_signed_token(auth_token)
    Base64.decode64(auth_token).split(':', 2).first
  end

  subject(:fetch) do
    post "/cmi5/tokens?id=#{item.id}", as: :json
  end

  describe 'with correct launch context' do
    let(:user) { create(:'account_service/user') }
    let(:item) { create(:cmi5_item) }
    let(:course) { create(:'course_service/course', :active) }
    let(:section) { create(:'course_service/section', course:) }
    let(:course_item) do
      create(
        :'course_service/item',
        section:,
        content_type: 'cmi5',
        content_id: item.id
      )
    end
    let(:enrollment) do
      create(
        :'course_service/enrollment',
        course:,
        user:
      )
    end

    before do
      sign_in(user: user)
      course_item
      enrollment
    end

    it 'returns an auth token' do
      fetch

      expect(response).to have_http_status(:ok)

      # Verify token is properly signed
      token = response.parsed_body['auth-token']
      verified = Cmi5::TokensController.verifier.verify(
        decode_signed_token(token),
        purpose: :cmi5_reporting
      )
      expect(verified).to eq('item_id' => item.id)
    end

    context 'with non-existent item' do
      let(:item) { nil }
      let(:course_item) { nil }
      let(:enrollment) { nil }

      it 'returns 404' do
        post "/cmi5/tokens?id=#{SecureRandom.uuid}", as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without an active enrollment' do
      let(:enrollment) { nil }

      it 'returns 401 Unauthorized' do
        fetch

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include('error' => 'Unauthorized')
      end
    end
  end

  describe 'without an authenticated user' do
    let(:item) { create(:cmi5_item) }

    it 'returns 401 Unauthorized' do
      fetch

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include('error' => 'Unauthorized')
    end
  end
end
