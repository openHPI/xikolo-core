# frozen_string_literal: true

require 'spec_helper'

describe 'APIv2: List courses', type: :request do
  subject(:request) do
    get '/api/v2/courses', headers:
  end

  let(:headers) { {} }

  context 'when unauthorized' do
    before do
      Stub.request(
        :course, :get, '/api/v2/course/courses',
        query: {embed: 'enrollment', page: 1, per_page: 500}
      ).to_return status: 401
    end

    it 'responds with Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end
end
