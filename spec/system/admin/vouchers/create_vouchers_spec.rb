# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Create Vouchers', type: :system do
  let(:user) { create(:'account_service/user', :admin) }

  before do
    xi_config <<~YML
      voucher:
        enabled: true
    YML

    sign_in(user:)
  end

  it 'generates voucher codes and displays them' do
    visit '/vouchers'

    fill_in 'Number of vouchers', with: '2'
    click_link_or_button 'Generate codes'

    expect(page).to have_text 'Generated voucher codes'
    expect(Voucher::Voucher.count).to eq 2
    Voucher::Voucher.ids.each do |code|
      expect(page).to have_text code
    end
  end
end
