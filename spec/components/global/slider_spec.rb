# frozen_string_literal: true

require 'spec_helper'

describe Global::Slider, type: :component do
  subject(:component) do
    described_class.new(variant:)
  end

  context 'with the light variant specified' do
    let(:variant) { :light }

    it 'renders the light variant' do
      render_inline(component)

      expect(page).to have_css('.slider--light')
    end
  end

  context 'with the dark variant specified' do
    let(:variant) { :dark }

    it 'renders the dark variant' do
      render_inline(component)

      expect(page).to have_css('.slider--dark')
    end
  end

  context 'without a specified variant' do
    subject(:component) { described_class.new }

    it 'renders the light variant' do
      render_inline(component)

      expect(page).to have_css('.slider--light')
    end
  end
end
