# frozen_string_literal: true

require 'spec_helper'

describe Smowl::Client do
  subject(:client) { described_class.new('https://results-api.smowltech.net/index.php/Restv1/{function}') }

  context 'with a successful client response' do
    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Function')
        .to_return Stub.json({FunctionResponse: {ack: 1}})
    end

    it 'returns a successful response object' do
      response = client.request('Function')
      expect(response).to be_a Smowl::Response
      expect(response).to be_success
      expect(response).to be_acknowledged
      expect(response.data).to eq({'ack' => 1})
    end
  end

  context 'with an error response' do
    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Function')
        .to_return Stub.json({
          status: 200,
          error: 200,
          messages: {error: 'No content.'},
        })
    end

    it 'the response indicates that an error occurred' do
      response = client.request('Function')
      expect(response).to be_a Smowl::Response
      expect(response).not_to be_success
      expect(response).not_to be_acknowledged
      expect(response.data).to be_nil
    end
  end

  context 'with invalid parameters provided' do
    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Function')
        .to_return Stub.json({
          status: 400,
          error: 400,
          messages: {error: {someField: 'The someField field is required.'}},
        }, status: 400)
    end

    it 'raises an internal exception' do
      expect { client.request('Function') }.to raise_error(Restify::ClientError)
    end
  end

  context 'with invalid authentication credentials' do
    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Function')
        .to_return Stub.json({
          status: 401,
          error: 401,
          messages: {error: 'Enter a correct Username and Password. If you do not know, contact us'},
        }, status: 401)
    end

    it 'raises an exception' do
      expect { client.request('Function') }.to raise_error(Restify::ClientError)
    end
  end

  context 'with an invalid function called' do
    before do
      stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Function')
        .to_return Stub.response(body: '', status: 404)
    end

    it 'raises an exception' do
      expect { client.request('Function') }.to raise_error(Restify::ClientError)
    end
  end
end
