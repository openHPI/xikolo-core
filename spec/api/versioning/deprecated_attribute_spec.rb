# frozen_string_literal: true

require 'spec_helper'

describe 'Versioning: Deprecating an attribute' do
  include Rack::Test::Methods

  def app
    @app ||= Xikolo::API.tap do |api|
      api.namespace 'attrs' do
        mount Class.new(Xikolo::Endpoint::CollectionEndpoint) {
          entity do
            type 'attr'
            attribute('bar') do
              version max: 2
              type :string
            end
            attribute('normal') do
              type :string
            end
          end

          collection do
            get 'Load all foo items' do
              [
                {'id' => 1, 'bar' => 'baz', 'normal' => 'val'},
                {'id' => 2, 'bar' => 'baz', 'normal' => 'val'},
              ]
            end
          end
        }
      end
    end
  end

  subject(:api_request) { get '/attrs/', nil, env_hash }

  before do
    allow(Xikolo::API).to receive(:supported_versions).and_return([
      Xikolo::Versioning::Version.new('2.8', expire_on: 5.days.from_now.to_date),
      Xikolo::Versioning::Version.new('3.0'),
    ])
  end

  let(:env_hash) { {} }

  let(:json_response) { JSON.parse(last_response.body) }

  context 'without explicitly requesting a version' do
    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'does not include the attribute' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).not_to include 'bar'
      end
    end
  end

  context 'when requesting the latest version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=3') }

    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'does not include the attribute' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).not_to include 'bar'
      end
    end
  end

  context 'when requesting the deprecated version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=2') }

    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'includes the attribute' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).to include 'bar'
      end
    end
  end
end
