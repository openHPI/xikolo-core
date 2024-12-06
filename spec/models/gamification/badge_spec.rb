# frozen_string_literal: true

require 'spec_helper'

describe Gamification::Badge, type: :model do
  context 'order' do
    before do
      user = create(:user)
      %i[bronze silver gold].each {|level| create(:gamification_badge, level, user:) }
      create_list(:gamification_badge, 3, :bronze, user:)
    end

    it 'return the highest level first' do
      expect(described_class.first.level).to eq 2
    end
  end
end
