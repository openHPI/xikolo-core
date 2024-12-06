# frozen_string_literal: true

require 'spec_helper'

describe Account::ChangePassword, type: :operation do
  subject(:operation) { described_class.call(current_user, params) }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.request(
      :account, :post, '/sessions',
      body: hash_including(ident: 'bob@example.com', password: 'old_secret')
    ).to_return check_password_response
  end

  let(:current_user) do
    Xikolo::Common::Auth::CurrentUser.from_session({
      'id' => current_session.id,
      'user_id' => user.id,
      'user' => {
        'anonymous' => false,
        'email' => 'bob@example.com',
      },
      'features' => current_user_features,
    })
  end
  let(:current_user_features) { {} }
  let(:user) { create(:user) }
  let(:current_session) { create(:session, user:) }
  let!(:other_sessions) { create_list(:session, 3, user:) }
  let!(:other_user_sessions) { create_list(:session, 2) }
  let(:params) do
    {
      old_password: 'old_secret',
      new_password: 'new_secret',
      password_confirmation: 'new_secret',
    }
  end

  let!(:change_password_stub) do
    Stub.request(:account, :patch, "/users/#{current_user.id}")
      .to_return change_password_response
  end
  let(:change_password_response) { Stub.response(status: 204) }
  let(:check_password_response) { Stub.json({user_id: user.id}) }

  it { is_expected.to be_success }

  it 'actually sets the new password via xi-account' do
    operation

    expect(
      change_password_stub.with(body: {password: 'new_secret'})
    ).to have_been_requested
  end

  it 'does not touch existing sessions by default' do
    expect { operation }.not_to change(Account::Session, :count).from(6)
  end

  context 'when configured via feature flipper' do
    let(:current_user_features) { {'password_change.remove_sessions' => true} }

    it { is_expected.to be_success }

    it "removes all of the user's sessions except for the current one" do
      expect { operation }.to change(Account::Session, :count).from(6).to(3)

      expect(current_session.reload).not_to be_destroyed
      other_sessions.each do |s|
        expect { s.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
      expect(other_user_sessions.map(&:reload)).to all be_persisted
    end
  end

  context 'when the old password is not correct' do
    let(:check_password_response) { Stub.json({errors: {ident: ['invalid_credentials']}}, status: 422) }

    it 'errors' do
      expect(operation).to be_error

      expect(
        operation.on {|result| result.error(&:message) }
      ).to include 'Did you forget your password?'
    end

    it 'does not try to change the password' do
      operation

      expect(change_password_stub).not_to have_been_requested
    end
  end

  context 'when the new password was not confirmed correctly' do
    let(:params) { super().merge(password_confirmation: 'typo') }

    it 'errors' do
      expect(operation).to be_error

      expect(
        operation.on {|result| result.error(&:message) }
      ).to eq 'Please make sure that "New password" and the "Password confirmation" are identical.'
    end

    it 'does not try to change the password' do
      operation

      expect(change_password_stub).not_to have_been_requested
    end
  end

  context 'when xi-account does not know this user' do
    let(:change_password_response) { Stub.response(status: 404) }

    it 'errors' do
      expect(operation).to be_error

      expect(
        operation.on {|result| result.error(&:message) }
      ).to include 'Saving your new password failed'
    end
  end

  context 'when the new password is not accepted by xi-account' do
    let(:change_password_response) { Stub.json({errors: {password: ['below_minimum_length']}}, status: 422) }

    it 'errors' do
      expect(operation).to be_error

      expect(
        operation.on {|result| result.error(&:message) }
      ).to include 'Saving your new password failed'
    end
  end
end
