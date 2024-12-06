# frozen_string_literal: true

require 'spec_helper'

describe Navigation::Logo, type: :component do
  subject(:component) do
    described_class.new(href:, alt:)
  end

  let(:href) { nil }
  let(:alt) { nil }

  describe 'with no config provided' do
    it 'has a default alt text' do
      render_inline(component)
      expect(page).to have_css("img[alt='Brand logo']")
    end
  end

  describe 'with a configuration provided' do
    let(:href) { 'www.example.com' }
    let(:alt) { 'All work and no play makes jack a dull boy' }

    it 'shows the logo and links to the given URL' do
      render_inline(component)
      expect(page).to have_link('', href: 'www.example.com')
      expect(page).to have_css("img[alt='All work and no play makes jack a dull boy']")
    end
  end
end
