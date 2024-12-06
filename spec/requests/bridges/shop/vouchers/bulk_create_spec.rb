# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Shop Bridge API: Vouchers: Bulk Create', type: :request do
  subject(:create_vouchers) do
    post '/bridges/shop/vouchers', headers:, params:
  end

  let(:token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }
  let(:params) { {product: 'course_reactivation', qty: '5', tag: 'shop', country: 'DE'} }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML
  end

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      create_vouchers

      expect(response).to have_http_status :unauthorized
    end
  end

  it 'creates 5 new vouchers with the requested properties' do
    expect { create_vouchers }.to change(Voucher::Voucher, :count).from(0).to(5)

    expect(Voucher::Voucher.all).to all have_attributes(
      product_type: 'course_reactivation',
      tag: 'shop',
      country: 'DE'
    )
  end

  it 'returns JSON serializations of the newly created vouchers, including the voucher codes' do
    create_vouchers

    expect(json).to match_array(Voucher::Voucher.all.map do |voucher|
      hash_including('id' => voucher.id, 'product' => 'course_reactivation')
    end)
  end

  context 'with error (missing attributes)' do
    let(:params) { {qty: '5'} }

    it 'does not create any vouchers' do
      expect { create_vouchers }.not_to change(Voucher::Voucher, :count)
    end

    it 'returns a JSON error' do
      create_vouchers

      expect(response).to have_http_status :unprocessable_entity
      expect(json).to eq({
        'errors' => {'country' => ['required'], 'product' => ['required']},
      })
    end
  end

  context 'with error (missing quantity)' do
    let(:params) { {product: 'course_reactivation', tag: 'shop', country: 'DE'} }

    it 'does not create any vouchers' do
      expect { create_vouchers }.not_to change(Voucher::Voucher, :count)
    end

    it 'returns a JSON error' do
      create_vouchers

      expect(response).to have_http_status :unprocessable_entity
      expect(json).to eq({
        'errors' => {'base' => ['Number must at least be 1']},
      })
    end
  end
end
