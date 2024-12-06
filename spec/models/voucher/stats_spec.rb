# frozen_string_literal: true

require 'spec_helper'

describe Voucher::Stats, type: :model do
  subject(:vouchers) { described_class.new }

  let(:course) { create(:course, course_code: 'pimpmaster3000') }

  before do
    # 10 unclaimed vouchers, 5 claimed ones and 3 tagged ones (also unclaimed)
    create_list(:voucher, 10, :reactivation)
    create_list(:voucher, 5, :reactivation, :claimed, course:)
    create_list(:voucher, 3, :reactivation, tag: 'p3k')
  end

  it 'contains correct stat numbers' do
    expect(vouchers.global.issued).to eq(18)
    expect(vouchers.global.claimed).to eq(5)
    expect(vouchers.global.percentage).to eq(27.78)

    expect(vouchers.by_product['course_reactivation'].issued).to eq(18)
    expect(vouchers.by_product['course_reactivation'].claimed).to eq(5)
    expect(vouchers.by_product['course_reactivation'].percentage).to eq(27.78)

    expect(vouchers.by_tag['p3k'].issued).to eq(3)
    expect(vouchers.by_tag['p3k'].claimed).to eq(0)
    expect(vouchers.by_tag['p3k'].percentage).to eq(0.0)
    expect(vouchers.by_tag['untagged'].issued).to eq(15)
    expect(vouchers.by_tag['untagged'].claimed).to eq(5)
    expect(vouchers.by_tag['untagged'].percentage).to eq(33.33)

    expect(vouchers.by_course['pimpmaster3000'].claimed).to eq(5)
  end
end
