# frozen_string_literal: true

require 'spec_helper'

describe 'Create user', type: :request do
  subject(:response) { request.value! }

  let(:request) { api.rel(:users).post(params) }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {**attributes_for(:user), email: 'root@localhost'} }
  let(:created_user) { User.find response['id'] }

  # test for side effects; we had an error declare ALL users as admin if
  # there exists an admin, so lets create one
  before { create(:user, :admin) }

  it 'creates new user' do
    expect { request.value! }.to change(User, :count).from(1).to(2)
  end

  it 'creates new email' do
    expect { request.value! }.to change(Email, :count).from(1).to(2)
  end

  describe 'newly created user record' do
    subject(:user) { created_user }

    it { is_expected.not_to be_confirmed }
    it { is_expected.not_to be_archived  }

    it 'checks profile completion status' do
      expect(user.features.pluck(:name)).to \
        eq %w[account.profile.mandatory_completed]
    end

    describe '#email' do
      subject { created_user.email }

      it { is_expected.to eq 'root@localhost' }
    end
  end

  it { is_expected.to respond_with :created }

  describe '#headers' do
    subject { response.response.headers.to_h }

    it { is_expected.to include 'LOCATION' => user_url(created_user) }
  end

  describe 'payload' do
    subject(:payload) { response.to_h }

    it do
      expect(payload).to include(
        'confirmed' => false,
        'archived' => false,
        'email' => 'root@localhost'
      )
    end
  end

  context 'with already taken email' do
    let!(:another_user) { create(:user) }

    let(:params) { {**super(), email: another_user.email} }

    it 'responds with 422 Unprocessable Entity' do
      expect { request.value! }.to raise_error(Restify::UnprocessableEntity)
    end

    it 'does not create new record' do
      expect { request.value }.not_to change(User, :count)
    end
  end

  context 'with affiliated: true' do
    subject(:payload) { response.to_h }

    let(:params) { {**super(), affiliated: true} }

    it { is_expected.to include 'affiliated' => true }
  end

  context 'with insufficient password' do
    describe '(password too short)' do
      let(:params) { super().merge password: 'katze' }

      it 'responds with 422 Unprocessable Entity' do
        expect { response }.to raise_error(Restify::UnprocessableEntity) do |err|
          expect(err.errors).to eq 'password' => ['below_minimum_length']
        end
      end
    end

    describe '(empty string)' do
      let(:params) { super().merge password: '' }

      it 'responds with 422 Unprocessable Entity' do
        expect { response }.to raise_error(Restify::UnprocessableEntity) do |err|
          expect(err.errors).to eq 'password' => ['below_minimum_length']
        end
      end
    end

    describe '(not existing)' do
      let(:params) { super().except(:password) }

      it { is_expected.to respond_with :created }
    end
  end
end
