# frozen_string_literal: true

require 'spec_helper'

describe Shorts::Carousel, type: :component do
  subject(:component) { Shorts::Carousel.new(items: items) }

  let(:items) do
    [
      {thumbnail: 'https://example.com/thumb1.jpg', id: 'short-1'},
      {thumbnail: 'https://example.com/thumb2.jpg', id: 'short-2'},
      {thumbnail: 'https://example.com/thumb3.jpg', id: 'short-3'},
    ]
  end

  it 'renders a carousel component' do
    render_inline(component)

    expect(page).to have_css('[role="region"][aria-roledescription="Carousel"][aria-label="Shorts"]')
    expect(page).to have_css('.x-carousel')
    expect(page).to have_css('.x-carousel-item', count: 9)
    expect(page).to have_css('img', count: 9)

    expect(page).to have_css('button[data-action="click->shorts-carousel#openDialog"]')
    expect(page).to have_css('video-player hlsjs-video[data-shorts-carousel-target="video"][loop][playsinline][disablepictureinpicture]')

    expect(page).to have_css('button[aria-label="Play video"]', count: 9)
    expect(page).to have_css('button[data-video-src="/shorts/short-1/signed_url"]', count: 3)
  end

  it 'renders a clone set on each side of the real items as scrolling room' do
    render_inline(component)

    expect(page).to have_css('[data-shorts-carousel-infinite-value="true"]')
    expect(page).to have_css('.x-carousel-item', count: 9)
    expect(page).to have_css('button.x-carousel-item[aria-hidden="true"][tabindex="-1"]', count: 6)

    carousel_items = page.all('.x-carousel-item')
    clone_pattern = carousel_items.map {|item| item[:'aria-hidden'] == 'true' }
    expect(clone_pattern).to eq([true, true, true, false, false, false, true, true, true])
  end

  it 'renders navigation buttons, hidden until scrolling is possible' do
    render_inline(component)

    expect(page).to have_css('button[data-action="click->shorts-carousel#scrollBack"][aria-label="Scroll back"][hidden]',
      visible: :hidden)
    expect(page).to have_css('button[data-action="click->shorts-carousel#scrollForward"][aria-label="Scroll forward"][hidden]',
      visible: :hidden)
  end

  context 'with too few items for infinite scrolling' do
    let(:items) do
      [
        {thumbnail: 'https://example.com/thumb1.jpg', id: 'short-1'},
        {thumbnail: 'https://example.com/thumb2.jpg', id: 'short-2'},
      ]
    end

    it 'renders a finite carousel without clones' do
      render_inline(component)

      expect(page).to have_css('[data-shorts-carousel-infinite-value="false"]')
      expect(page).to have_css('.x-carousel-item', count: 2)
      expect(page).to have_no_css('.x-carousel-item[aria-hidden="true"]')
    end
  end

  context 'without items' do
    let(:items) { [] }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('.x-carousel')
      expect(page).to have_no_css('.x-carousel-item')
    end
  end
end
