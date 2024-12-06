# frozen_string_literal: true

require 'xikolo/common/rspec/stub'
require 'net/http'

RSpec.describe Xikolo::Common::RSpec::Stub do
  before(:all) { Xikolo::Common::API.assign :the_service, 'http://example.de/service' }

  describe '#request' do
    before do
      # Stub GET requests to a path
      Stub.service(:the_service)
    end

    it 'stubs requests to the given URL' do
      Stub.request(:the_service, :get, '/stars').to_return status: 200
      response = Net::HTTP.get_response('example.de', '/service/stars')
      expect(response.code).to eq '200'
    end

    it 'stubs requests to URLs matching URI templates' do
      template = Addressable::Template.new('/stars/{id}')
      Stub.request(:the_service, :get, template).to_return status: 200
      response = Net::HTTP.get_response('example.de', '/service/stars/123')
      expect(response.code).to eq '200'
    end

    it 'does not stub other requests' do
      Stub.request(:the_service, :get, '/stars').to_return status: 200
      expect do
        Net::HTTP.get_response('example.de', '/service/other')
      end.to raise_error(WebMock::NetConnectNotAllowedError)
    end

    context 'without service' do
      it 'raises an ArgumentError' do
        expect do
          Stub.request(:the_missing_service, :get, '/')
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe '#service' do
    before do
      # Stub the service's root URL
      Stub.service(:the_service,
        courses_url: 'http://example.de/service/courses',
        reviews_url: 'http://example.de/service/reviews')
    end

    it 'stubs requests to the service base URL' do
      response = Net::HTTP.get_response('example.de', '/service')
      expect(response.code).to eq '200'
    end

    it 'returns the hash of URLs as JSON-encoded response body' do
      response = Net::HTTP.get_response('example.de', '/service')
      expect(JSON.parse(response.body)).to eq(
        'courses_url' => 'http://example.de/service/courses',
        'reviews_url' => 'http://example.de/service/reviews'
      )
    end
  end

  describe '#response' do
    before do
      # Stub a request to return with a JSON body
      Stub.service(:the_service)
      Stub.request(:the_service, :get, '/any').to_return Stub.response(
        body: 'I am a text response',
        headers: {'Content-Type' => 'text/plain'},
        **other_kwargs
      )
    end
    let(:other_kwargs) { {} }

    it 'stubs requests to respond with a successful HTTP response' do
      response = Net::HTTP.get_response('example.de', '/service/any')
      expect(response.code).to eq '200'
    end

    it 'returns with the configured headers' do
      response = Net::HTTP.get_response('example.de', '/service/any')
      expect(response.content_type).to eq 'text/plain'
    end

    it 'returns the given string in the response body' do
      response = Net::HTTP.get_response('example.de', '/service/any')
      expect(response.body).to eq 'I am a text response'
    end

    describe 'overwriting the status code' do
      let(:other_kwargs) { {status: 404} }

      it 'stubs requests to have the given status code' do
        response = Net::HTTP.get_response('example.de', '/service/any')
        expect(response.code).to eq '404'
      end
    end

    describe 'with links' do
      let(:other_kwargs) do
        {
          links: {
            work: 'https://example.de',
            life: 'https://facebook.com',
            balance: 'https://www.google.de',
          },
        }
      end

      it 'adds the named links to the response as headers' do
        response = Net::HTTP.get_response('example.de', '/service/any')
        expect(response['Link']).to eq \
          '<https://example.de>;rel=work, <https://facebook.com>;rel=life, <https://www.google.de>;rel=balance'
      end
    end
  end

  describe '#json' do
    before do
      # Stub a request to return with a JSON body
      Stub.service(:the_service)
      Stub.request(:the_service, :get, '/json').to_return Stub.json([
        {id: 1, title: 'Title 1'},
        {id: 2, title: 'Title 2'},
      ], **kwargs)
    end
    let(:kwargs) { {} }

    it 'stubs requests to respond with a successful HTTP response' do
      response = Net::HTTP.get_response('example.de', '/service/json')
      expect(response.code).to eq '200'
    end

    it 'returns with the appropriate Content-Type header for JSON responses' do
      response = Net::HTTP.get_response('example.de', '/service/json')
      expect(response.content_type).to eq 'application/json'
    end

    it 'encodes the given object as JSON in the response body' do
      response = Net::HTTP.get_response('example.de', '/service/json')
      expect(JSON.parse(response.body)).to eq [
        {'id' => 1, 'title' => 'Title 1'},
        {'id' => 2, 'title' => 'Title 2'},
      ]
    end

    context 'with custom headers (string keys)' do
      let(:kwargs) { {headers: {'X-Foo' => 'Bar'}} }

      it 'includes the given header in the stubbed HTTP response' do
        response = Net::HTTP.get_response('example.de', '/service/json')
        expect(response['X-Foo']).to eq 'Bar'
      end
    end
  end
end
