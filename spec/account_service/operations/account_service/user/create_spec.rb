# frozen_string_literal: true

require 'spec_helper'

describe AccountService::User::Create, type: :operation do
  subject(:operation) { described_class.new(attributes) }

  let(:attributes) do
    {
      full_name: 'John Doe',
      email: 'john@example.org',
      password: 'secret123',
      status: 'other',
    }
  end

  it 'creates a new user record' do
    expect { operation.call }.to change(AccountService::User, :count).from(0).to(1)
  end

  it 'creates a new email record' do
    expect { operation.call }.to change(AccountService::Email, :count).from(0).to(1)
  end

  describe 'new user record' do
    subject(:user) { AccountService::User.first }

    before { operation.call }

    it { expect(user.full_name).to eq 'John Doe' }
    it { expect(user.email).to eq 'john@example.org' }
  end

  describe 'new email record' do
    subject(:email) { AccountService::Email.first }

    before { operation.call }

    it { expect(email.user_id).to eq AccountService::User.first.id }
    it { expect(email.address).to eq 'john@example.org' }
    it { is_expected.to be_primary }
    it { is_expected.not_to be_confirmed }
  end

  context 'with email address conflict' do
    before { create(:'account_service/email', address: 'john@example.org') }

    it do
      expect { operation.call }.to raise_error do |err|
        expect(err).to be_a ActiveRecord::RecordInvalid

        expect(err.record).to be_a AccountService::User
        expect(err.record.id).to be_nil
        expect(err.record.errors[:email]).to eq ['has already been taken']
      end
    end

    it 'does not publish event' do
      expect(Msgr).not_to receive :publish
      begin
        operation.call
      rescue StandardError
        ActiveRecord::RecordInvalid
      end
    end
  end
end
