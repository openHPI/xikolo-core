# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::GamificationBadge, type: :component do
  subject(:component) { described_class.new(badge) }

  context 'with gained badge' do
    let(:badge) { create(:gamification_badge, :gold, name: 'selftest_master') }

    it 'renders a real badge image matching the level' do
      render_inline(component)

      image = page.find('img')
      expect(image[:alt]).to eq 'Selftest Master (Gold)'
      expect(image[:src]).to match %r{\A/assets/gamification/badges/selftest_master_2-[a-z0-9]+.png}
    end
  end

  context 'without gained badge' do
    let(:badge) { Gamification::Badge.new(name: 'selftest_master', level: 2) }

    it 'renders a dimmed badge image' do
      render_inline(component)

      image = page.find('img')
      expect(image[:alt]).to eq 'Selftest Master'
      expect(image[:src]).to match %r{\A/assets/gamification/badges/selftest_master_not_gained-[a-z0-9]+.png}
    end
  end
end
