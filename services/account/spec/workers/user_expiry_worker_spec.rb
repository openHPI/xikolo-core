# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

RSpec.describe UserExpiryWorker do
  subject(:perform) do
    Sidekiq::Testing.inline! do
      described_class.perform_async(threshold.to_s)
    end
  end

  let(:threshold) { 3.years.ago.to_date }
  let!(:old_user) { create(:'account_service/user', :unconfirmed, last_access: (threshold - 1.day).to_date) }

  before do
    create(:'account_service/user', :unconfirmed, created_at: 2.days.ago, last_access: nil)
    create(:'account_service/user', last_access: nil)
    create(:'account_service/user', created_at: 4.years.ago, last_access: threshold)
    create(:'account_service/user', :archived, created_at: 20.days.ago, last_access: 2.weeks.ago.to_date)
  end

  it 'deletes non-archived user accounts with no activity after the threshold' do
    expect(User::Destroy).to receive(:call).once.with(old_user)
    perform
  end
end
