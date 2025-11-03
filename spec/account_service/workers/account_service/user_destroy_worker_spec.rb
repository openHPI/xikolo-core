# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

RSpec.describe AccountService::UserDestroyWorker do
  subject(:perform) do
    Sidekiq::Testing.inline! do
      described_class.perform_async(user.id, threshold)
    end
  end

  let(:threshold) { nil }
  let!(:user) { create(:'account_service/user', :unconfirmed) }

  it 'calls User::Destroy for the user' do
    expect(AccountService::User::Destroy).to receive(:call).once.with(user)
    perform
  end

  context 'with last access before threshold date' do
    let(:threshold) { '2024-07-26' }
    let!(:user) { create(:'account_service/user', :unconfirmed, last_access: '2024-07-25') }

    it 'destroy the user record' do
      expect(AccountService::User::Destroy).to receive(:call).once.with(user)
      perform
    end
  end

  context 'with last access after threshold date' do
    let(:threshold) { '2024-07-26' }
    let(:user) { create(:'account_service/user', :unconfirmed, last_access: '2024-07-26') }

    it 'does not destroy the user record' do
      expect(AccountService::User::Destroy).not_to receive(:call)
      perform
    end
  end

  context 'without last access and a threshold date given' do
    let(:threshold) { '2024-07-26' }
    let(:user) { create(:'account_service/user', :unconfirmed) }

    it 'does not destroy the user record' do
      expect(AccountService::User::Destroy).not_to receive(:call)
      perform
    end
  end

  context 'with error while deleting' do
    it 'retries calling User::Destroy' do
      expect(AccountService::User::Destroy).to receive(:call).once.with(user).and_raise(RuntimeError)
      expect(AccountService::User::Destroy).to receive(:call).once.with(user)

      expect { perform }.to raise_error(RuntimeError)
      perform
    end
  end
end
