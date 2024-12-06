# frozen_string_literal: true

require 'spec_helper'

describe 'Portal API: Create enrollment', type: :request do
  subject(:request) { post '/portalapi-beta/enrollments', params:, headers: }

  let(:headers) { {} }
  let(:params) { {} }
  let(:json) { JSON.parse response.body }
  let(:enrollment) { build(:'course:enrollment', user_id: authorization['user_id']) }
  let(:authorization) { build(:'account:authorization') }
  let(:uid) { authorization['uid'] }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.service(:course, build(:'course:root'))

    Stub.request(:account, :get, '/authorizations', query: {uid:})
      .to_return Stub.json([authorization])
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

  context 'with an invalid authorization token' do
    let(:headers) { super().merge('Authorization' => 'Bearer canihackyou') }

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

  context 'with an Authorization header (with a hardcoded token)' do
    let(:headers) { super().merge('Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966') }

    context 'without an Accept header' do
      let(:headers) { super().merge('Accept' => nil) }

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

    context 'with an unsupported content type in the Accept header (obsolete version)' do
      let(:headers) { super().merge('Accept' => 'application/vnd.openhpi.enrollment+json;v=0.9') }

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

    context 'with a supported content type in the Accept header (current version)' do
      let(:headers) { super().merge('Accept' => 'application/vnd.openhpi.enrollment+json;v=1.0') }

      context 'without a user ID' do
        let(:params) do
          super().merge(course_id: enrollment['course_id'])
        end

        it 'responds with HTTP 422' do
          request
          expect(response).to have_http_status :unprocessable_entity
          expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
          expect(json).to eq(
            'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#parameter_missing',
            'title' => 'The user_id and course_id cannot be blank.',
            'status' => 422
          )
        end
      end

      context 'with an unknown user' do
        let(:uid) { 'unkown-saml-uid' }
        let(:params) do
          super().merge(user_id: uid, course_id: enrollment['course_id'])
        end

        before do
          Stub.request(:account, :get, '/authorizations', query: {uid:})
            .to_return Stub.response(status: 404)
        end

        it 'responds with HTTP 404 Not Found' do
          request
          expect(response).to have_http_status :not_found
          expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
          expect(json).to eq(
            'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#course_or_user_not_found',
            'title' => 'Course or user not found.',
            'status' => 404
          )
        end
      end

      context 'with an unknown course' do
        let(:unknown_course_id) { generate(:course_id) }
        let(:params) do
          super().merge(user_id: uid, course_id: unknown_course_id)
        end

        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {
              user_id: authorization['user_id'],
              course_id: params[:course_id],
              learning_evaluation: true,
            }
          ).to_return Stub.response(status: 404)
        end

        it 'responds with HTTP 404 Not Found' do
          request
          expect(response).to have_http_status :not_found
          expect(response.headers['Content-Type']).to include 'application/problem+json'
          expect(json).to eq(
            'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#course_or_user_not_found',
            'title' => 'Course or user not found.',
            'status' => 404
          )
        end
      end

      context 'with valid parameters' do
        let(:params) do
          super().merge(user_id: uid, course_id: enrollment['course_id'])
        end
        let(:enrollments_response) { [] }

        let!(:create_enrollment_stub) do
          Stub.request(
            :course, :post, '/enrollments',
            body: {
              user_id: enrollment['user_id'],
              course_id: enrollment['course_id'],
            }
          ).to_return Stub.json(enrollment)
        end

        before do
          Stub.request(
            :course, :get, '/enrollments',
            query: {
              user_id: enrollment['user_id'],
              course_id: enrollment['course_id'],
              learning_evaluation: true,
            }
          ).to_return Stub.json(enrollments_response)
        end

        it 'creates and returns the enrollment' do
          request
          expect(create_enrollment_stub).to have_been_requested
          expect(response).to have_http_status :created
          expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.enrollment+json;v=1.0'
          expect(json).to eq({
            'id' => enrollment['id'],
            'course_id' => enrollment['course_id'],
            'user_id' => authorization['uid'],
          })
        end

        context 'when the enrollment already exists' do
          let(:enrollments_response) { [enrollment] }

          it 'responds with HTTP 409' do
            request
            expect(response).to have_http_status :conflict
            expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
            expect(json).to eq(
              'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#enrollment_already_present',
              'title' => 'An enrollment for this user and course already exists.',
              'status' => 409
            )
          end
        end
      end
    end
  end
end
