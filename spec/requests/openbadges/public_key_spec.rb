# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OpenBadge: PublicKey', type: :request do
  subject { get '/openbadges/v2/public_key' }

  let(:authentic_response) { JSON.parse(key_response.body) }
  let(:key_response) { subject }

  let(:issuer_path) { '/openbadges/v2/issuer.json' }
  let(:public_key_path) { '/openbadges/v2/public_key.json' }

  describe 'response' do
    subject { super(); response }

    context 'when open_badges option enabled in config' do
      before do
        xi_config <<~YML
          open_badges:
            enabled: true
            public_key: ''
        YML
      end

      it 'returns correct HTTP status' do
        expect(key_response.status).to equal(200)
      end

      it 'returns valid json' do
        expect(key_response.header['Content-Type']).to eql('application/json; charset=utf-8')
        expect { authentic_response }.not_to raise_error
      end

      it 'returns valid public key structure' do
        expect(authentic_response.values).to all(be_an_instance_of(String))
      end

      it 'returns valid public key attributes' do
        expect(authentic_response['@context']).to eql('https://w3id.org/openbadges/v2')
        expect(authentic_response['type']).to eql('CryptographicKey')
        expect(
          URI.parse(authentic_response['id']).path
        ).to eql(public_key_path)
        expect(
          URI.parse(authentic_response['owner']).path
        ).to eql(issuer_path)
      end
    end

    context 'when open_badges option disabled in config' do
      before do
        xi_config <<~YML
          open_badges:
            enabled: false
        YML
      end

      it 'returns not_found HTTP status' do
        expect(key_response.status).to equal(404)
      end

      it 'returns nothing' do
        expect(key_response.body).to be_empty
      end
    end
  end
end
