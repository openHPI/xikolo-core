# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Shop Bridge API: Vouchers: Index', type: :request do
  subject(:list_vouchers) do
    get '/bridges/shop/vouchers', headers:, params:
  end

  let(:token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }
  let(:params) { {} }

  let!(:voucher_claimed) { create(:voucher, :reactivation, :claimed, tag: 'shop') }
  let!(:voucher_claimed_today) { create(:voucher, :reactivation, :claimed, claimed_at: DateTime.now, tag: 'shop') }
  let!(:voucher_proctoring) { create(:voucher, :proctoring, tag: 'shop') }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    create_list(:voucher, 5, :reactivation)
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      list_vouchers

      expect(response).to have_http_status :unauthorized
    end
  end

  context 'w/o tag' do
    let(:params) { {tag: ''} }

    it 'returns all vouchers' do
      list_vouchers

      expect(json.size).to eq 8
    end
  end

  context 'w/ tag' do
    let(:params) { {tag: 'shop'} }

    it 'returns vouchers with specific tag' do
      list_vouchers

      expect(json).to contain_exactly(hash_including('id' => voucher_claimed.id), hash_including('id' => voucher_claimed_today.id), hash_including('id' => voucher_proctoring.id))
    end
  end

  context 'when filtering for any claimed vouchers' do
    let(:params) { {claimed: 'true'} }

    it 'returns the claimed vouchers unfiltered by date' do
      list_vouchers

      expect(json).to contain_exactly(hash_including('id' => voucher_claimed.id), hash_including('id' => voucher_claimed_today.id))
    end
  end

  context 'when filtering for claimed vouchers in a specific timeframe' do
    let(:params) { {claimed: 'true', start_date: start_date.iso8601(3), end_date: end_date.iso8601(3)} }
    let(:start_date) { 30.days.ago }
    let(:end_date) { 1.day.ago }

    it 'returns id, date and country of all vouchers claimed between start and end date' do
      expect(voucher_claimed.claimed_at).to be > start_date
      expect(voucher_claimed.claimed_at).to be < end_date
      expect(voucher_claimed_today.claimed_at).to be > end_date

      list_vouchers

      expect(json).to match [hash_including(
        'id' => voucher_claimed.id,
        'claimed_at' => voucher_claimed.claimed_at.iso8601(3),
        'claimant_ip' => voucher_claimed.claimant_ip.to_s,
        'claimant_country' => voucher_claimed.claimant_country
      )]
    end
  end

  describe 'pagination (GET)' do
    it 'links to other pages in headers' do
      list_vouchers

      expect(response.headers['Link']).to match(/<.+\?page=1>; rel="first"/)
      expect(response.headers['Link']).to match(/<.+\?page=1>; rel="last"/)
      expect(response.headers['Link']).not_to include 'rel="next"'
    end

    it 'includes paging information in headers' do
      list_vouchers

      expect(response.headers['X-Total-Pages']).to eq '1'
      expect(response.headers['X-Total-Count']).to eq '8'
      expect(response.headers['X-Current-Page']).to eq '1'
    end
  end

  describe 'pagination (HEAD)' do
    subject(:list_vouchers) { head '/bridges/shop/vouchers', headers:, params: }

    it 'has an empty body' do
      list_vouchers

      expect(response.body).to be_empty
    end

    it 'links to other pages in headers' do
      list_vouchers

      expect(response.headers['Link']).to match(/<.+\?page=1>; rel="first"/)
      expect(response.headers['Link']).to match(/<.+\?page=1>; rel="last"/)
      expect(response.headers['Link']).not_to include 'rel="next"'
    end

    it 'includes paging information in headers' do
      list_vouchers

      expect(response.headers['X-Total-Pages']).to eq '1'
      expect(response.headers['X-Total-Count']).to eq '8'
      expect(response.headers['X-Current-Page']).to eq '1'
    end
  end
end
