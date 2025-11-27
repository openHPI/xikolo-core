# frozen_string_literal: true

require 'spec_helper'

describe Home::Promotion, type: :component do
  subject(:component) do
    described_class.new(
      'Component title',
      'Component text which is somewhat longer',
      **options
    )
  end

  let(:options) { {} }

  it 'renders the title and text' do
    render_inline(component)

    expect(page).to have_content 'Component title'
    expect(page).to have_content 'Component text which is somewhat longer'
    expect(page).to have_no_link
  end

  context 'with image' do
    let(:options) { {image_url: '/image.png'} }

    it 'styles the component for the image' do
      render_inline(component)

      expect(page).to have_css '.promotion--with-image'
      expect(page).to have_css '.promotion__overlay--secondary'
    end
  end

  context 'with image and a color variant' do
    let(:options) { {image_url: '/image.png', variant: :black} }

    it 'styles the component for the image with the color variant' do
      render_inline(component)

      expect(page).to have_css('.promotion--with-image')
      expect(page).to have_css('.promotion__overlay--black')
    end
  end

  context 'with a link to open in a new tab' do
    let(:options) { {link_url: '/about', target: 'blank'} }

    it 'renders a link to the specified URL and opens it in a new tab' do
      render_inline(component)

      expect(page).to have_content 'Component title'
      expect(page).to have_content 'Component text which is somewhat longer'
      expect(page).to have_css("a[href='/about'][target='_blank'][rel='noopener']")
      expect(page).to have_no_css('.promotion--with-image')
    end
  end

  context 'with a download link' do
    let(:options) { {link_url: '/document.pdf', download: true} }

    it 'renders a link with download attribute' do
      render_inline(component)
      expect(page).to have_link(href: '/document.pdf', download: true)
    end
  end

  context 'with a download link and custom filename' do
    let(:options) { {link_url: '/document.pdf', download: 'custom-filename.pdf'} }

    it 'renders a link with download attribute and custom filename' do
      render_inline(component)
      expect(page).to have_link(href: '/document.pdf', download: 'custom-filename.pdf')
    end
  end
end
