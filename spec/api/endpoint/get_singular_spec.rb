# frozen_string_literal: true

require 'spec_helper'

# See http://jsonapi.org/format/#fetching-resources
describe 'RESTful retrieval of singular resources' do
  include Rack::Test::Methods

  def app
    @app ||= Class.new(Xikolo::Endpoint::SingularEndpoint)
  end

  subject(:response) { get '/' }

  before do
    app.entity do
      type 'profile'
      id { 'profile' }
      attribute('name') do
        type :string
      end
    end

    blk = get_block
    app.member do
      get 'Retrieve the resource', &blk
    end
  end

  describe 'successful retrieval' do
    let(:get_block) do
      proc {
        # Some code that returns a resource
        {
          'title' => 'will_be_gone',
          'name' => 'The resource name',
        }
      }
    end

    # A server MUST respond to a successful request to fetch an individual resource or resource collection with a
    # 200 OK response.
    it 'responds with 200 Ok' do
      expect(response.status).to eq 200
    end

    it 'has the correct Content-Type header' do
      expect(response.headers['Content-Type']).to eq 'application/vnd.api+json'
    end

    describe 'JSON body' do
      subject(:json) { JSON.parse(response.body) }

      it { is_expected.to include 'data' }

      it 'serializes type and ID correctly' do
        expect(json['data']).to include('type' => 'profile', 'id' => 'profile')
      end

      it 'serializes the attributes correctly' do
        expect(json['data']).to include('attributes')
        expect(json['data']['attributes']).to eq('name' => 'The resource name')
      end
    end
  end
end
