# frozen_string_literal: true

require 'spec_helper'

describe Home::HeadHero, type: :component do
  subject(:component) do
    described_class.new('Awesome slogan', call_to_action:, image:)
  end

  let(:call_to_action) { {} }
  let(:image) { {} }

  describe 'simple component' do
    it 'renders a heading without a call to action link' do
      render_inline(component)

      expect(page).to have_css 'h1', text: 'Awesome slogan'
      expect(page).to have_no_link
    end
  end

  describe 'with call to action' do
    let(:call_to_action) { {text: 'Click here', link: '/about'} }

    it 'renders a link to the specified url' do
      render_inline(component)

      expect(page).to have_link 'Click here', href: '/about'
    end
  end

  describe 'with only the image url' do
    let(:image) { {url: '/image.png'} }

    it 'renders an empty alt text' do
      render_inline(component)

      expect(page).to have_css("img[src*='/image.png'][alt='']")
    end

    it 'does not control the navigation logo appearance' do
      render_inline(component)

      expect(page).to have_no_css("[data-id='head-hero-image']")
    end
  end

  describe 'with an image and alt text' do
    let(:image) { {url: '/image.png', alt: 'Image description'} }

    it 'renders the configured alt text' do
      render_inline(component)

      expect(page).to have_css("img[src*='/image.png'][alt='Image description']")
    end
  end

  describe 'with an image that is hooked to the navigation logo' do
    let(:image) { {url: '/image.png', dim_nav_logo: true} }

    it 'makes the navigation logo appear dimmed until scrolling over the image' do
      render_inline(component)

      expect(page).to have_css("[data-id='head-hero-image']")
    end
  end
end
