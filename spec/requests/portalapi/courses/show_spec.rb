# frozen_string_literal: true

require 'spec_helper'

describe 'Portal API: Show course', type: :request do
  subject(:request) { get url, headers: }

  let(:url) { course_list.first['url'] }
  let(:headers) { {} }
  let(:json) { JSON.parse response.body }
  let(:course_list) do
    get '/portalapi-beta/courses', headers: {
      'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966',
      'Accept' => 'application/vnd.openhpi.list+json;v=1.1',
    }
    JSON.parse(response.body)['items']
  end
  let(:first_course) { build(:'course:course', :german) }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses', query: hash_including(:page))
      .to_return Stub.json([
        first_course,
        build(:'course:course'),
        build(:'course:course'),
        build(:'course:course'),
      ])
    Stub.request(:course, :get, "/courses/#{first_course['id']}")
      .to_return Stub.json(first_course)
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

    context 'Accept=application/vnd.openhpi.course+json;v=0.9 (obsolete)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.course+json;v=0.9')
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

    context 'Accept=application/vnd.openhpi.course+json;v=1.0 (old, but still supported)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.course+json;v=1.0')
      end

      it 'responds with the latest matching content type' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.course+json;v=1.1'
        expect(response.headers['Link']).to match(/<.+>; rel="self"/)
        expect(json).to include(
          'title', 'abstract', 'description', 'start_date', 'end_date', 'language' => 'de', 'id' => first_course['id']
        )
      end
    end

    context 'Accept=application/vnd.openhpi.course+json;v=1.1 (current version)' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.course+json;v=1.1')
      end

      it 'responds with the requested content type' do
        request
        expect(response).to have_http_status :ok
        expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.course+json;v=1.1'
        expect(response.headers['Link']).to match(/<.+>; rel="self"/)
        expect(json).to include(
          'title', 'abstract', 'description', 'start_date', 'end_date', 'language' => 'de', 'id' => first_course['id']
        )
      end
    end
  end

  describe 'authorization / error handling' do
    # People may try to manually construct URLs to other courses.
    # We don't want to expose any kind of non-public courses.
    let(:url) { "/portalapi-beta/courses/#{course_id}" }
    let(:course_id) { generate(:course_id) }
    let(:headers) do
      super().merge(
        'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966',
        'Accept' => 'application/vnd.openhpi.course+json;v=1.1'
      )
    end

    context 'when the course does not exist' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.response(status: 404)
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end

    context 'trying to access a hidden course' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.json build(:'course:course', id: course_id, hidden: true)
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end

    context 'trying to access an external course' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.json build(:'course:course', id: course_id, external_course_url: 'https://teach.me.stuff')
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end

    context 'trying to access a course in preparation' do
      before do
        Stub.request(:course, :get, "/courses/#{course_id}")
          .to_return Stub.json build(:'course:course', id: course_id, status: 'preparation')
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end
  end
end
