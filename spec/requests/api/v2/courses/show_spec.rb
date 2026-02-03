# frozen_string_literal: true

require 'spec_helper'

describe 'APIv2: Show course', type: :request do
  subject(:request) do
    get '/api/v2/courses/code', headers:
  end

  let(:headers) { {} }

  context 'with non-existent course' do
    before do
      Stub.request(
        :course, :get, '/api/v2/course/courses/code',
        query: {embed: 'description,enrollment'}
      ).to_return status: 404
    end

    it 'responds with 404 Not Found' do
      request
      expect(response).to have_http_status :not_found
    end
  end
end
