# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OpenBadge: Issuer', type: :request do
  subject { get '/openbadges/v2/issuer' }

  let(:authentic_response) { JSON.parse(issuer_response.body) }
  let(:issuer_response) { subject }

  let(:issuer_path) { '/openbadges/v2/issuer.json' }
  let(:public_key_path) { '/openbadges/v2/public_key.json' }
  let(:revocation_list_path) { '/openbadges/v2/revocation_list.json' }

  describe 'response' do
    subject { super(); response }

    context 'when open_badges option enabled in config' do
      before do
        xi_config <<~YML
          open_badges:
            enabled: true
            issuer_image: ''
        YML
      end

      it 'returns correct HTTP status' do
        expect(issuer_response.status).to equal(200)
      end

      it 'returns valid json' do
        expect(issuer_response.header['Content-Type']).to eql('application/json; charset=utf-8')
        expect { authentic_response }.not_to raise_error
      end

      it 'returns valid issuer structure' do
        expect(authentic_response.values).to all(be_an_instance_of(String))
      end

      it 'returns valid issuer attributes' do
        expect(authentic_response['@context']).to eql('https://w3id.org/openbadges/v2')
        expect(authentic_response['type']).to eql('Issuer')
        expect(
          URI.parse(authentic_response['id']).path
        ).to eql(issuer_path)
        expect(
          URI.parse(authentic_response['publicKey']).path
        ).to eql(public_key_path)
        expect(
          URI.parse(authentic_response['revocationList']).path
        ).to eql(revocation_list_path)
      end

      describe '(issuer_description)' do
        it 'returns the default description in english' do
          expect(authentic_response['description']).to eq 'Xikolo is an online learning platform, based on Xikolo.'
        end

        context 'with english not available as platform locale' do
          before do
            xi_config <<~YML
              locales:
                available: ['de']
                default: de
            YML
          end

          it 'returns the default description in the default platform locale' do
            expect(authentic_response['description']).to eq 'Xikolo is eine Online-Lernplattform, basierend auf Xikolo.'
          end
        end

        context 'with a default locale without existing translation' do
          before do
            xi_config <<~YML
              locales:
                available: ['de', 'fr']
                default: fr
            YML
          end

          it 'returns the default description in english' do
            expect(authentic_response['description']).to eq 'Xikolo is an online learning platform, based on Xikolo.'
          end
        end
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
        expect(issuer_response.status).to equal(404)
      end

      it 'returns nothing' do
        expect(issuer_response.body).to be_empty
      end
    end
  end
end
