# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Profile: Update', type: :request do
  subject(:result) { post '/dashboard/profile', params: profile_params, headers: }

  before do
    stub_user_request(id: user_id, features:)

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json build(:'account:user', id: user_id)
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:features) { {} }
  let(:profile_params) { {} }

  let!(:update_profile_stub) do
    Stub.request(:account, :put, "/users/#{user_id}")
  end

  context 'with the profile feature flipper' do
    let(:features) { {'profile' => 'true'} }

    describe 'update full_name and display_name' do
      context 'with HTML special chars' do
        let(:profile_params) do
          {
            full_name: 'Fest & Flauschig',
            display_name: 'Übel & Gefährlich',
          }
        end

        it 'preserves the ampersand when updating name fields' do
          result

          expect(
            update_profile_stub.with(body: hash_including(
              full_name: 'Fest & Flauschig',
              display_name: 'Übel & Gefährlich'
            ))
          ).to have_been_requested
        end
      end

      context 'with HTML tags' do
        let(:profile_params) do
          {
            full_name: '<a href="google.de">Google</a>',
          }
        end

        it 'escapes the HTML tags in the response' do
          result

          full_name_response = response.parsed_body['user']['full_name']
          expect(full_name_response).to eq '&lt;a href=&quot;google.de&quot;&gt;Google&lt;/a&gt;'
        end
      end

      context 'with additional whitespaces' do
        let(:profile_params) do
          {
            full_name: 'Test   User  ',
            display_name: ' T.   User  ',
          }
        end

        it 'squeezes and strips whitespaces in names' do
          result

          full_name_response = response.parsed_body['user']['full_name']
          display_name_response = response.parsed_body['user']['display_name']
          expect(full_name_response).to eq 'Test User'
          expect(display_name_response).to eq 'T. User'
        end

        it 'updates the user record accordingly' do
          result

          expect(
            update_profile_stub.with(body: hash_including(
              full_name: 'Test User',
              display_name: 'T. User'
            ))
          ).to have_been_requested
        end
      end
    end
  end

  context 'without the profile feature flipper' do
    it 'cannot be accessed' do
      expect { result }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
