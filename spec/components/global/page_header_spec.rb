# frozen_string_literal: true

require 'spec_helper'

describe Global::PageHeader, type: :component do
  subject(:component) do
    described_class.new('Quantencomputing Summer School')
  end

  describe 'simple' do
    it 'renders the title' do
      render_inline(component)
      expect(page).to have_text 'Quantencomputing Summer School'
    end
  end

  describe 'with defined language' do
    subject(:component) do
      described_class.new('Quantencomputing-Sommerschule', lang: 'DE')
    end

    it 'includes the lang attribute' do
      render_inline(component)
      expect(page).to have_text 'Quantencomputing-Sommerschule'
      expect(page).to have_css("[lang='DE']")
    end
  end

  describe 'with pill' do
    it 'renders the title and the pill' do
      render_inline(component) do |c|
        c.with_pill 'Active course'
      end

      render_inline(component)
      expect(page).to have_text 'Quantencomputing Summer School'
      expect(page).to have_text 'Active course'
    end
  end

  describe 'with subtitle' do
    subject(:component) do
      described_class.new('Quantencomputing Summer School', subtitle: 'Offered by Grandmaster Yoda')
    end

    it 'renders the title and the subtitle' do
      render_inline(component)
      expect(page).to have_text 'Quantencomputing Summer School'
      expect(page).to have_text 'Offered by Grandmaster Yoda'
    end
  end

  describe 'with additional content' do
    it 'renders the title and the included additional content' do
      render_inline(component) { '<a href=/about>More information</a>'.html_safe }

      expect(page).to have_text 'Quantencomputing Summer School'
      expect(page).to have_link 'More information', href: '/about'
    end
  end
end
