# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin: Vouchers: Create', type: :request do
  subject(:create_voucher) { post '/vouchers', params:, headers: }

  let(:params) { {product_type: 'course_reactivation', count: '1', tag: '', claimant_id: '', course_id: '', expires_at: ''} }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    stub_user_request permissions: ['course.vouchers.issue']

    Stub.request(:course, :get, '/courses', query: hash_including({}))
      .to_return Stub.json([])
  end

  it 'creates a new voucher' do
    expect { create_voucher }.to change(Voucher::Voucher, :count).from(0).to(1)
  end

  it 'displays the voucher code on the page' do
    create_voucher
    expect(response.body).to include Voucher::Voucher.last.id
  end

  context 'without product' do
    let(:params) { super().merge product_type: nil }

    it 'displays error messages' do
      create_voucher
      expect(response.body).to include 'Product type required'
    end
  end

  describe 'bulk voucher creation' do
    let(:params) { super().merge count: '10' }

    it 'creates multiple new vouchers at once' do
      expect { create_voucher }.to change(Voucher::Voucher, :count).from(0).to(10)
    end

    it 'displays all created voucher codes on the page' do
      create_voucher
      expect(response.body).to include(*Voucher::Voucher.ids)
    end

    context 'with invalid count value' do
      let(:params) { super().merge count: '0' }

      it 'displays an error message' do
        create_voucher
        expect(response.body).to include 'Number must at least be 1'
      end
    end

    context 'with too many vouchers' do
      let(:params) { super().merge count: '501' }

      it 'displays an error message' do
        create_voucher
        expect(response.body).to include 'Too many vouchers requested'
      end
    end
  end
end
