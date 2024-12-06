# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OpenBadge: RevocationList', type: :request do
  subject { get '/openbadges/v2/revocation_list' }

  let(:authentic_response) { JSON.parse(list_response.body) }
  let(:list_response) { subject }

  let(:issuer_path) { '/openbadges/v2/issuer.json' }
  let(:revocation_list_path) { '/openbadges/v2/revocation_list.json' }

  describe 'response' do
    subject { super(); response }

    context 'when open_badges option enabled in config' do
      before do
        xi_config <<~YML
          open_badges:
            enabled: true
        YML
      end

      it 'returns correct HTTP status' do
        expect(list_response.status).to equal(200)
      end

      it 'returns valid json' do
        expect(list_response.header['Content-Type']).to eql('application/json; charset=utf-8')
        expect { authentic_response }.not_to raise_error
      end

      it 'returns valid revocation list structure' do
        expect(authentic_response['@context']).to be_an_instance_of(String)
        expect(authentic_response['type']).to be_an_instance_of(String)
        expect(authentic_response['id']).to be_an_instance_of(String)
        expect(authentic_response['issuer']).to be_an_instance_of(String)
        expect(authentic_response['revokedAssertions']).to be_an_instance_of(Array)
      end

      it 'returns valid revocation list attributes' do
        expect(authentic_response['@context']).to eql('https://w3id.org/openbadges/v2')
        expect(authentic_response['type']).to eql('RevocationList')
        expect(
          URI.parse(authentic_response['id']).path
        ).to eql(revocation_list_path)
        expect(
          URI.parse(authentic_response['issuer']).path
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
        expect(list_response.status).to equal(404)
      end

      it 'returns nothing' do
        expect(list_response.body).to be_empty
      end
    end
  end
end
