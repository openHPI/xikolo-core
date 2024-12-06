# frozen_string_literal: true

require 'spec_helper'

describe 'Versioning: Deprecating an API endpoint' do
  include Rack::Test::Methods

  def app
    @app ||= Xikolo::API.tap do |api|
      api.namespace 'deprecateds' do
        mount Class.new(Xikolo::Endpoint::CollectionEndpoint) {
          version max: 2

          entity do
            type 'deprecated'
            attribute('info') do
              type :string
            end
          end

          collection do
            get 'Load all deprecated items' do
              [{'id' => 1}, {'id' => 2}]
            end
          end
        }
      end
    end
  end

  subject(:api_request) { get '/deprecateds/', nil, env_hash }

  before do
    allow(Xikolo::API).to receive(:supported_versions).and_return([
      Xikolo::Versioning::Version.new('2.8', expire_on: 5.days.from_now.to_date),
      Xikolo::Versioning::Version.new('3.0'),
    ])
  end

  let(:env_hash) { {} }

  context 'without explicitly requesting a version' do
    it 'does not know the endpoint' do
      api_request
      expect(last_response.status).to eq 404
    end
  end

  context 'when requesting the latest version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=3') }

    it 'does not know the endpoint' do
      api_request
      expect(last_response.status).to eq 404
    end
  end

  context 'when requesting the deprecated version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=2') }

    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'returns the collection' do
      api_request
      json = JSON.parse(last_response.body)
      expect(json).to eq(
        'data' => [
          {
            'type' => 'deprecated',
            'id' => 1,
            'attributes' => {'info' => nil},
          },
          {
            'type' => 'deprecated',
            'id' => 2,
            'attributes' => {'info' => nil},
          },
        ]
      )
    end
  end
end
