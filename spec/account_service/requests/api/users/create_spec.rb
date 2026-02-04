# frozen_string_literal: true

require 'spec_helper'

describe 'Create user', type: :request do
  subject(:response) { request.value! }

  let(:request) { api.rel(:users).post(data) }

  let(:api) { restify_with_headers(account_service_url).get.value! }
  let(:data) { {**attributes_for(:'account_service/user'), email: 'root@localhost.de'} }
  let(:created_user) { AccountService::User.find response['id'] }

  # test for side effects; we had an error declare ALL users as admin if
  # there exists an admin, so lets create one
  before { create(:'account_service/user', :admin) }

  it 'creates new user' do
    expect { request.value! }.to change(AccountService::User, :count).from(1).to(2)
  end

  it 'creates new email' do
    expect { request.value! }.to change(AccountService::Email, :count).from(1).to(2)
  end

  describe 'newly created user record' do
    subject(:user) { created_user }

    it { is_expected.not_to be_confirmed }
    it { is_expected.not_to be_archived  }

    describe '#email' do
      subject { created_user.email }

      it { is_expected.to eq 'root@localhost.de' }
    end
  end

  it { is_expected.to respond_with :created }

  describe '#headers' do
    subject { response.response.headers.to_h }

    it { is_expected.to include 'LOCATION' => account_service.user_url(created_user) }
  end

  describe 'payload' do
    subject(:payload) { response.to_h }

    it do
      expect(payload).to include(
        'confirmed' => false,
        'archived' => false,
        'email' => 'root@localhost.de'
      )
    end
  end

  context 'with already taken email' do
    let!(:another_user) { create(:'account_service/user') }

    let(:data) { {**super(), email: another_user.email} }

    it 'responds with 422 Unprocessable Entity' do
      expect { request.value! }.to raise_error(Restify::UnprocessableEntity)
    end

    it 'does not create new record' do
      expect { request.value }.not_to change(AccountService::User, :count)
    end
  end

  context 'with affiliated: true' do
    subject(:payload) { response.to_h }

    let(:data) { {**super(), affiliated: true} }

    it { is_expected.to include 'affiliated' => true }
  end

  context 'with insufficient password' do
    describe '(password too short)' do
      let(:data) { super().merge password: 'katze' }

      it 'responds with 422 Unprocessable Entity' do
        expect { response }.to raise_error(Restify::UnprocessableEntity) do |err|
          expect(err.errors).to eq 'password' => ['below_minimum_length']
        end
      end
    end

    describe '(empty string)' do
      let(:data) { super().merge password: '' }

      it 'responds with 422 Unprocessable Entity' do
        expect { response }.to raise_error(Restify::UnprocessableEntity) do |err|
          expect(err.errors).to eq 'password' => ['below_minimum_length']
        end
      end
    end

    describe '(not existing)' do
      let(:data) { super().except(:password) }

      it { is_expected.to respond_with :created }
    end
  end
end
