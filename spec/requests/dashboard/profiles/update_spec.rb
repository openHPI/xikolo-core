# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Profile: Update', type: :request do
  subject(:update_profile) do
    patch '/dashboard/profile',
      params: {xikolo_account_user: params},
      headers:
  end

  before do
    stub_user_request(id: user_id, features:)

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json(user_resource)
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:user_resource) { build(:'account:user', id: user_id) }
  let(:features) { {} }
  let(:params) { {} }

  context 'with the profile feature flipper' do
    let(:update_profile_stub) do
      Stub.request(:account, :put, "/users/#{user_id}")
    end
    let(:features) { {'profile' => 'true'} }

    before do
      update_profile_stub
    end

    describe 'update full_name' do
      context 'with valid HTML special chars' do
        let(:params) { {full_name: 'Fest & Flauschig'} }

        it 'preserves the ampersand when updating full name field' do
          update_profile
          expect(
            update_profile_stub.with(body: hash_including(
              full_name: 'Fest & Flauschig'
            ))
          ).to have_been_requested
          expect(flash[:success].first).to eq 'The profile has been updated.'
        end
      end

      context 'with invalid HTML special chars' do
        let(:params) { {full_name: 'Fest / Flauschig'} }
        # The presenter is required to re-render the edit view after failing to update the user
        let(:profile_presenter) { instance_double(Account::ProfilePresenter) }

        before do
          profile_presenter
          update_profile_stub.to_return(Stub.json(
            {errors: {full_name: ['is invalid']}},
            status: 422
          ))
        end

        it 'does not update when a "/" is present in the name' do
          update_profile
          expect(update_profile_stub).to have_been_requested
          expect(flash[:error].first).to eq 'The profile has not been updated.'
        end
      end

      context 'with additional whitespaces in the beginning or end' do
        let(:params) do
          {
            display_name: '  T. User  ',
          }
        end

        it 'strips whitespaces in names' do
          update_profile
          expect(
            update_profile_stub.with(body: hash_including(
              display_name: '  T. User  '
            ))
          ).to have_been_requested
          expect(flash[:success].first).to eq 'The profile has been updated.'
        end
      end
    end
  end

  context 'without the profile feature flipper' do
    it 'cannot be accessed' do
      expect { update_profile }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
