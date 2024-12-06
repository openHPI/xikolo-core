# frozen_string_literal: true

require 'spec_helper'

describe 'Portal API: List courses', type: :request do
  subject(:request) do
    get '/portalapi-beta/courses', headers:, params:
  end

  before do
    Stub.service(:course, build(:'course:root'))
    stub_course_list
  end

  let(:headers) { {} }
  let(:params) { {} }
  let(:json) { JSON.parse response.body }

  let(:stub_course_list) do
    Stub.request(:course, :get, '/courses', query: hash_including(:page))
      .to_return Stub.json([
        build(:'course:course'),
        build(:'course:course'),
        build(:'course:course'),
        build(:'course:course'),
      ])
  end

  context 'without Authorization header' do
    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="test-realm"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#unauthenticated',
        'title' => 'You must provide an Authorization header to access this resource.',
        'status' => 401
      )
    end

    it 'answers in context of the configured realm' do
      request
      expect(response.header['WWW-Authenticate']).to include('realm="test-realm"')
    end
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) do
      super().merge('Authorization' => 'Bearer canihackyou')
    end

    it 'responds with 401 Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
      expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="test-realm", error="invalid_token"'
      expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
      expect(json).to eq(
        'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#invalid_token',
        'title' => 'The bearer token you provided was invalid, has expired or has been revoked.',
        'status' => 401
      )
    end
  end

  context 'when authorized (with a hardcoded token)' do
    let(:headers) do
      super().merge('Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966')
    end

    context 'without Accept header' do
      let(:headers) do
        super().merge('Accept' => nil)
      end

      it 'responds with HTTP 406 Not Acceptable' do
        request
        expect(response).to have_http_status :not_acceptable
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#accept_header_missing',
          'title' => 'You must provide the desired content type in the Accept request header.',
          'status' => 406
        )
      end
    end

    context 'Accept=application/vnd.openhpi.list+json;v=0.9 (obsolete)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.list+json;v=0.9')
      end

      it 'responds with HTTP 406 Not Acceptable' do
        request
        expect(response).to have_http_status :not_acceptable
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#unsupported_content_type',
          'title' => 'The media type provided in the "Accept" request header is not supported by this endpoint.',
          'status' => 406
        )
      end
    end

    context 'Accept=application/vnd.openhpi.list+json;v=1.0 (old, but still supported)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.list+json;v=1.0')
      end

      it 'responds with the latest matching content type' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.list+json;v=1.1'
        expect(json['items'].length).to eq 4
        expect(json['items']).to all include('url')
      end
    end

    context 'Accept=application/vnd.openhpi.list+json;v=1.1 (current version)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.list+json;v=1.1')
      end

      it 'responds with the requested content type' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.list+json;v=1.1'
        expect(json['items'].length).to eq 4
        expect(json['items']).to all include('url')
      end
    end
  end

  describe 'pagination' do
    let(:headers) do
      super().merge(
        'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966',
        'Accept' => 'application/vnd.openhpi.list+json;v=1.1'
      )
    end

    context 'when another page exists' do
      let(:stub_course_list) do
        Stub.request(:course, :get, '/courses', query: hash_including(page: '1'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {next: '/courses?p=2'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '2'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=1'}
          )
      end

      it 'also links to the next page in the response header' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Link']).to match(/<.+\?page=2>; rel="next"/)
        expect(json['items'].length).to eq 3
      end
    end

    context 'when there is a previous and a next page' do
      let(:params) { {page: 2} }
      let(:stub_course_list) do
        Stub.request(:course, :get, '/courses', query: hash_including(page: '1'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {next: '/courses?p=2'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '2'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=1', next: '/courses?p=3'}
          )

        Stub.request(:course, :get, '/courses', query: hash_including(page: '3'))
          .to_return Stub.json(
            [build(:'course:course'), build(:'course:course')],
            links: {prev: '/courses?p=2'}
          )
      end

      it 'links to both the previous and the next page in the response header' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Link']).to match(/<.+\?page=1>; rel="prev"/)
        expect(response.headers['Link']).to match(/<.+\?page=3>; rel="next"/)
        expect(json['items'].length).to eq 3
      end
    end
  end
end
