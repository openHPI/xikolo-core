# frozen_string_literal: true

require 'spec_helper'

describe Home::Tile, type: :component do
  describe 'simple component' do
    subject(:component) do
      described_class.new('Tile title')
    end

    it 'renders the title' do
      render_inline(component)

      expect(page).to have_text 'Tile title'
      expect(page).to have_no_link
    end
  end

  describe 'with secondary text' do
    subject(:component) do
      described_class.new('Tile title', text: 'Secondary text')
    end

    it 'renders the title and the secondary text' do
      render_inline(component)

      expect(page).to have_text 'Tile title'
      expect(page).to have_text 'Secondary text'
    end
  end

  describe 'with more link' do
    subject(:component) do
      described_class.new('Tile title', link: '/about')
    end

    it 'renders a link to the specified url with the default "More" text' do
      render_inline(component)

      expect(page).to have_link 'More', href: '/about'
    end

    context 'with custom link text' do
      subject(:component) do
        described_class.new('Tile title', link: {text: 'About us', url: '/about'})
      end

      it 'renders a link to the specified url with the custom text' do
        render_inline(component)

        expect(page).to have_link 'About us', href: '/about'
      end
    end
  end

  describe 'with image' do
    subject(:component) do
      described_class.new('Tile title', image: {url: '/image.png', alt: 'Image description'})
    end

    it 'renders the image' do
      render_inline(component)

      expect(page).to have_css("img[alt='Image description']")
      expect(page).to have_no_css('img[srcset]')
    end

    context 'providing images for retina displays (.2x)' do
      before do
        allow(Rails.application.assets_manifest).to receive(:find_sources)
          .with('/image.2x.png')
          .and_return(['image'])
      end

      it 'lists alternative image sizes' do
        render_inline(component)

        expect(page).to have_css("img[alt='Image description'][srcset = '/image.png, /image.2x.png 2x']")
      end
    end
  end
end
