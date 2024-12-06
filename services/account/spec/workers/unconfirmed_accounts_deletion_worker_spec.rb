# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UnconfirmedAccountsDeletionWorker do
  subject(:worker) { described_class.new.perform }

  let!(:unconfirmed_user) { create(:user, :unconfirmed, created_at: 4.days.ago) }

  before do
    create(:user, :unconfirmed, created_at: 2.days.ago)
    create(:user, created_at: 4.days.ago)
    create(:user)
    create(:user, :archived, created_at: 20.days.ago)
  end

  it 'deletes user accounts after confirmation period has expired (3 days)' do
    worker
    expect { unconfirmed_user.reload }.to raise_error ActiveRecord::RecordNotFound
  end

  it 'does not delete confirmed accounts' do
    expect { worker }.not_to change { User.confirmed.count }
  end

  it 'does not delete archived accounts even though they are marked unconfirmed' do
    # Archived, i.e. deleted, users are marked as unconfirmed as well upon
    # deletion. We do not want to delete those!
    expect { worker }.not_to change { User.archived.count }
  end
end
