# frozen_string_literal: true

require 'spec_helper'

describe Voucher::Voucher, type: :model do
  describe '.claimed' do
    subject(:claimed) { described_class.claimed }

    before do
      create(:voucher, :reactivation)
      create(:voucher, :reactivation, :claimed, tag: 'shop')
      create(:voucher, :reactivation, :claimed, claimed_at: Time.current, tag: 'shop')
      create(:voucher, :proctoring, tag: 'shop')
      create(:voucher, :proctoring, :claimed)
    end

    it 'returns claimed vouchers only' do
      expect(claimed).to contain_exactly(an_object_having_attributes(claimed?: true, tag: 'shop'), an_object_having_attributes(claimed?: true, tag: 'shop'), an_object_having_attributes(claimed?: true, tag: 'untagged'))
    end
  end

  describe '(validations)' do
    subject { voucher }

    let(:voucher) { create(:voucher, :reactivation) }

    it { is_expected.to accept_values_for :product_type, 'proctoring_smowl' }
    it { is_expected.to accept_values_for :product_type, 'course_reactivation' }
    it { is_expected.not_to accept_values_for :product_type, 'unknown' }

    describe 'claimant IP' do
      let(:claim_attrs) do
        {
          course_id: generate(:course_id),
          claimed_at: Time.current,
          claimant_id: generate(:user_id),
          claimant_country: 'DEU',
        }
      end

      it 'does not accept invalid IP addresses' do
        expect { voucher.update!(**claim_attrs, claimant_ip: 'invalid') }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq claimant_ip: %w[required]
        end
      end

      it 'accepts valid IPv4 addresses' do
        expect { voucher.update!(**claim_attrs, claimant_ip: '0.0.0.0') }.not_to raise_error
      end

      it 'accepts valid IPv6 addresses' do
        expect { voucher.update!(**claim_attrs, claimant_ip: '0:0:0:0:0:0:0:0') }.not_to raise_error
      end
    end

    describe 'claimant country' do
      let(:claim_attrs) do
        {
          course_id: generate(:course_id),
          claimed_at: DateTime.current,
          claimant_id: generate(:user_id),
          claimant_ip: '::',
        }
      end

      it 'does not accept incorrect country codes' do
        expect { voucher.update!(**claim_attrs, claimant_country: 'de') }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq claimant_country: %w[invalid]
        end
      end

      it 'accepts ISO 3166-1 alpha-3 formatted country codes' do
        expect { voucher.update!(**claim_attrs, claimant_country: 'DEU') }.not_to raise_error
      end
    end
  end
end
