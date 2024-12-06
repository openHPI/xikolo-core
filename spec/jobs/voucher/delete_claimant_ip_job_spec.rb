# frozen_string_literal: true

require 'spec_helper'

describe Voucher::DeleteClaimantIPJob, type: :job do
  subject(:enqueue_job) { described_class.perform_later }

  let!(:applicable_voucher) do
    create(:voucher, :reactivation, :claimed,
      claimed_at: 5.years.ago,
      claimant_ip: '127.0.0.1')
  end
  let!(:recent_voucher) do
    create(:voucher, :reactivation, :claimed,
      claimed_at: 6.days.ago,
      claimant_ip: '127.0.0.1')
  end
  let!(:no_ip_voucher) do
    create(:voucher, :reactivation, :claimed,
      claimed_at: 5.years.ago,
      claimant_ip: nil)
  end
  let!(:unclaimed_voucher) { create(:voucher, :reactivation) }

  it 'enqueues a new job' do
    expect { enqueue_job }.to have_enqueued_job(described_class).on_queue('default')
  end

  describe '#perform' do
    around {|example| perform_enqueued_jobs(&example) }

    it 'affects applicable voucher' do
      expect { enqueue_job }.to change { applicable_voucher.reload.claimant_ip }.to(nil)
    end

    it 'ignores too recent vouchers' do
      expect { enqueue_job }.not_to change { recent_voucher.reload.claimant_ip }.from(IPAddr.new('127.0.0.1'))
    end

    it 'does not alter vouchers without IP' do
      expect { enqueue_job }.not_to change { no_ip_voucher.reload.claimant_ip }.from(nil)
    end

    it 'ignores unclaimed vouchers' do
      expect { enqueue_job }.not_to change { unclaimed_voucher.reload.claimant_ip }.from(nil)
    end
  end
end
