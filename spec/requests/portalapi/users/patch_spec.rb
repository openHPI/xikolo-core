# frozen_string_literal: true

require 'spec_helper'

describe 'Portal API: Patch user', type: :request do
  subject(:request) do
    patch "/portalapi-beta/users/#{auth_id}", headers:, params: body
  end

  let(:headers) { {} }
  let(:body) { '' }
  let(:json) { JSON.parse response.body }
  let(:user) { build(:'account:user', avatar_url: 'https://example.com/existing_avatar.png') }
  let(:email) { build(:'account:email', user_id: user['id']) }
  let(:authorization) { build(:'account:authorization', user_id: user['id']) }
  let(:auth_id) { authorization['uid'] }
  let(:user_attributes) { {language: 'en'} }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(:account, :get, '/authorizations', query: {uid: auth_id})
      .to_return Stub.json([authorization])
    Stub.request(:account, :get, "/users/#{user['id']}")
      .to_return Stub.json(user)
    Stub.request(:account, :get, "/users/#{user['id']}/emails")
      .to_return Stub.json([email])
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

  shared_examples_for 'a successful request' do
    it { expect(response).to have_http_status :ok }
    it { expect(response.headers['Content-Type']).to eq 'application/vnd.openhpi.user+json;v=1.0; charset=utf-8' }
  end

  shared_examples_for 'an unsuccessful request' do
    it { expect(response).to have_http_status :unprocessable_entity }
    it { expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8' }

    it 'returns the proper error message' do
      expect(json).to eq(
        'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#email_update',
        'title' => 'The user email address could not be updated.',
        'status' => 422
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

    context 'with an invalid Accept header' do
      let(:headers) do
        super().merge('Accept' => 'application/vnd.openhpi.user+json;v=0.9')
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

    context 'with a valid Accept header' do
      let(:headers) { super().merge('Accept' => 'application/vnd.openhpi.user+json;v=1.0') }

      let!(:replace_emails_stub) do
        Stub.request(:account, :put, "/users/#{user['id']}/emails",
          body: [{
            address: 'foo@bar.com',
            confirmed: true,
            primary: true,
          }].to_json).to_return Stub.json([{address: 'foo@bar.com', confirmed: true, primary: true}])
      end

      let!(:update_user_attributes_stub) do
        Stub.request(:account, :patch, "/users/#{user['id']}", body: user_attributes)
          .to_return Stub.json({id: user['id'], **user_attributes})
      end

      before { request }

      context 'when only the user email address is sent on the request' do
        let(:body) { {email: 'foo@bar.com'} }

        context 'and the email address replacement succeeds' do
          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).to have_been_requested }
          it { expect(update_user_attributes_stub).not_to have_been_requested }

          it 'returns the updated user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => 'foo@bar.com',
              'born_at' => nil,
              'language' => user['language'],
              'avatar' => 'https://example.com/existing_avatar.png'
            )
          end
        end

        context 'and the email address replacement returns an error' do
          let(:body) { {email: 'invalid-email'} }

          let!(:replace_emails_stub) do
            Stub.request(:account, :put, "/users/#{user['id']}/emails",
              body: [{
                address: 'invalid-email',
                confirmed: true,
                primary: true,
              }].to_json).to_return Stub.response(status: 422)
          end

          it_behaves_like 'an unsuccessful request'

          it { expect(replace_emails_stub).to have_been_requested }
          it { expect(update_user_attributes_stub).not_to have_been_requested }
        end
      end

      context 'when the email address is not sent on the request' do
        let(:body) { user_attributes }

        context 'and the user attributes update succeeds' do
          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).not_to have_been_requested }
          it { expect(update_user_attributes_stub).to have_been_requested }

          it 'returns the updated user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => user['email'],
              'born_at' => nil,
              'language' => 'en',
              'avatar' => user['avatar_url']
            )
          end
        end

        context 'and the user attributes update returns an error' do
          let(:body) { {language: '12345'} }

          let!(:update_user_attributes_stub) do
            Stub.request(:account, :patch, "/users/#{user['id']}", body: {language: '12345'})
              .to_return Stub.response(status: 422)
          end

          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).not_to have_been_requested }
          it { expect(update_user_attributes_stub).to have_been_requested }

          it 'returns the user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => user['email'],
              'born_at' => nil,
              'language' => user['language'],
              'avatar' => user['avatar_url']
            )
          end
        end
      end

      context 'when both the user email address and other user attributes are sent on the request' do
        let(:body) { {email: 'foo@bar.com', language: 'en'} }

        context 'and both the email address replacement and user attributes update succeed' do
          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).to have_been_requested }
          it { expect(update_user_attributes_stub).to have_been_requested }

          it 'returns the updated user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => 'foo@bar.com',
              'born_at' => nil,
              'language' => 'en',
              'avatar' => user['avatar_url']
            )
          end
        end

        context 'and the email address replacement succeeds, but the user attributes update fails' do
          let(:body) { {email: 'foo@bar.com', language: '12345'} }

          let!(:update_user_attributes_stub) do
            Stub.request(:account, :patch, "/users/#{user['id']}", body: {language: '12345'})
              .to_return Stub.response(status: 422)
          end

          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).to have_been_requested }
          it { expect(update_user_attributes_stub).to have_been_requested }

          it 'returns the updated user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => 'foo@bar.com',
              'born_at' => nil,
              'language' => user['language'],
              'avatar' => user['avatar_url']
            )
          end
        end

        context 'and the email address replacement update fails' do
          let(:body) { {email: 'invalid-email', language: 'en'} }

          let!(:replace_emails_stub) do
            Stub.request(:account, :put, "/users/#{user['id']}/emails",
              body: [{
                address: 'invalid-email',
                confirmed: true,
                primary: true,
              }].to_json).to_return Stub.response(status: 422)
          end

          it { expect(replace_emails_stub).to have_been_requested }
          it { expect(update_user_attributes_stub).not_to have_been_requested }

          it_behaves_like 'an unsuccessful request'
        end
      end

      context 'when multiple user attributes are sent on the request' do
        let(:user_attributes) do
          {
            full_name: 'New full name',
            display_name: 'New display name',
            born_at: '2000-01-01',
          }
        end

        let(:body) { user_attributes }

        context 'and all user attribute updates succeed' do
          context 'when the avatar attribute is not sent on the request' do
            it_behaves_like 'a successful request'

            it { expect(replace_emails_stub).not_to have_been_requested }
            it { expect(update_user_attributes_stub).to have_been_requested }

            it 'returns the updated user resource with all sent attributes' do
              expect(update_user_attributes_stub).to have_been_requested
              expect(json).to eq(
                'id' => auth_id,
                'full_name' => 'New full name',
                'display_name' => 'New display name',
                'email' => user['email'],
                'born_at' => '2000-01-01',
                'language' => user['language'],
                'avatar' => 'https://example.com/existing_avatar.png'
              )
            end
          end

          context 'when the (external) user avatar is updated' do
            let(:user_attributes) { super().merge(avatar_url: 'https://example.com/new_avatar.jpg') }
            let(:body) do
              {
                full_name: 'New full name',
                display_name: 'New display name',
                born_at: '2000-01-01',
                avatar: 'https://example.com/new_avatar.jpg',
              }
            end
            let(:sanitized_params) do
              body.merge(avatar_uri: body[:avatar]).except(:avatar)
            end

            let!(:update_user_attributes_stub) do
              Stub.request(:account, :patch, "/users/#{user['id']}", body: sanitized_params)
                .to_return Stub.json({id: user['id'], **user_attributes})
            end

            it_behaves_like 'a successful request'

            it 'returns the updated user resource' do
              expect(update_user_attributes_stub).to have_been_requested
              expect(json).to eq(
                'id' => auth_id,
                'full_name' => 'New full name',
                'display_name' => 'New display name',
                'email' => user['email'],
                'born_at' => '2000-01-01',
                'language' => user['language'],
                'avatar' => 'https://example.com/new_avatar.jpg'
              )
            end
          end
        end

        context 'and the user attributes update returns an error' do
          let(:user_attributes) { super().merge(language: '12345') }

          let!(:update_user_attributes_stub) do
            Stub.request(:account, :patch, "/users/#{user['id']}", body: user_attributes)
              .to_return Stub.response(status: 422)
          end

          it_behaves_like 'a successful request'

          it { expect(replace_emails_stub).not_to have_been_requested }
          it { expect(update_user_attributes_stub).to have_been_requested }

          it 'returns the unmodified user resource' do
            expect(json).to eq(
              'id' => auth_id,
              'full_name' => user['full_name'],
              'display_name' => user['display_name'],
              'email' => user['email'],
              'born_at' => nil,
              'language' => user['language'],
              'avatar' => user['avatar_url']
            )
          end
        end
      end

      context 'when the avatar is requested to be deleted' do
        let(:user_attributes) { {avatar_url: nil} }
        let(:body) { {avatar: nil} }

        let!(:update_user_attributes_stub) do
          Stub.request(:account, :patch, "/users/#{user['id']}", body: {avatar_uri: nil})
            .to_return Stub.json({id: user['id'], **user_attributes})
        end

        it_behaves_like 'a successful request'

        it 'returns the updated user resource' do
          expect(update_user_attributes_stub).to have_been_requested
          expect(json).to eq(
            'id' => auth_id,
            'full_name' => user['full_name'],
            'display_name' => user['display_name'],
            'email' => user['email'],
            'born_at' => nil,
            'language' => user['language'],
            'avatar' => nil
          )
        end
      end
    end
  end

  describe 'authorization / error handling' do
    let(:headers) do
      super().merge(
        'Authorization' => 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966',
        'Accept' => 'application/vnd.openhpi.user+json;v=1.0'
      )
    end

    context 'when the user authorization does not exist' do
      let(:body) { {email: 'foo@bar.com'} }

      before do
        Stub.request(:account, :get, '/authorizations', query: {uid: auth_id})
          .to_return Stub.json([])
      end

      it 'responds with 404 Not Found' do
        request
        expect(response).to have_http_status :not_found
      end
    end

    context 'with an empty request body' do
      it 'responds with HTTP 400 Bad Request' do
        request
        expect(response).to have_http_status :bad_request
        expect(response.headers['Content-Type']).to eq 'application/problem+json; charset=utf-8'
        expect(json).to eq(
          'type' => 'https://openhpi.stoplight.io/docs/portal-api/068d6638d8e0b-errors#empty_request_body',
          'title' => 'The request body cannot be blank.',
          'status' => 400
        )
      end
    end
  end
end
