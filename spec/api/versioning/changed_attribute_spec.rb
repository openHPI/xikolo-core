# frozen_string_literal: true

require 'spec_helper'

describe 'Versioning: Changing an attribute' do
  include Rack::Test::Methods

  def app
    @app ||= Xikolo::API.tap do |api|
      api.namespace 'changed' do
        mount Class.new(Xikolo::Endpoint::CollectionEndpoint) {
          entity do
            type 'changed'
            attribute('bar') do
              version max: 2
              type :string
              reading { 'old' }
            end
            attribute('bar') do
              version min: 3
              type :string
              reading { 'new' }
            end
          end

          collection do
            get 'Load all foo items' do
              [
                {'id' => 1, 'bar' => 'baz'},
                {'id' => 2, 'bar' => 'baz'},
              ]
            end
          end
        }
      end
    end
  end

  subject(:api_request) { get '/changed/', nil, env_hash }

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

    it 'returns the new attribute value' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).to include 'bar' => 'new'
      end
    end
  end

  context 'when requesting the latest version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=3') }

    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'returns the new attribute value' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).to include 'bar' => 'new'
      end
    end
  end

  context 'when requesting the deprecated version' do
    let(:env_hash) { super().merge('HTTP_ACCEPT' => 'application/vnd.api+json; xikolo-version=2') }

    it 'responds with 200 Ok' do
      api_request
      expect(last_response.status).to eq 200
    end

    it 'returns the old attribute value' do
      api_request
      json_response['data'].each do |entity|
        expect(entity['attributes']).to include 'bar' => 'old'
      end
    end
  end
end
