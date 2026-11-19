# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Vouchers: Query', type: :request do
  subject(:page) { get '/vouchers/query', params: {code:} }

  let(:code) { generate(:uuid) }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    sign_in(user: create(:'account_service/user', :admin))
  end

  context 'with existing voucher' do
    before do
      create(:voucher, :reactivation, id: code)
    end

    it 'lists the voucher code with details' do
      page
      expect(response.body).to include 'Voucher Code', code, 'Claimed?'
    end
  end

  context 'without a matching voucher' do
    it 'displays an error message' do
      page
      expect(response.body).to include 'The voucher code you have supplied is not valid. Please check your code.'
    end
  end
end
