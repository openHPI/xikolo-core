# frozen_string_literal: true

require 'spec_helper'

describe Course::Channel, '.not_deleted', type: :model do
  subject(:scope) { described_class.not_deleted }

  let!(:channel) { create(:channel) }

  before { create(:channel, archived: true) }

  it 'returns only non-archived channels' do
    expect(scope).to contain_exactly(channel)
  end
end
