# frozen_string_literal: true

require 'spec_helper'

describe Shorts::Deck, type: :component do
  subject(:component) { described_class.new(items: items) }

  let(:items) do
    (1..5).map { {id: "short-#{it}", thumbnail: "https://example.com/thumb#{it}.jpg"} }
  end

  it 'renders a basic deck with the shared player and navigation' do
    render_inline(component)

    expect(page).to have_css('[role="region"][aria-roledescription="Carousel"][aria-label="Shorts"]')
    expect(page).to have_css('[data-shorts-player-target="item"]', count: 5, visible: :all)
    expect(page).to have_css('[data-action="click->shorts-deck#previous"]')
    expect(page).to have_css('[data-action="click->shorts-deck#next"]')
    expect(page).to have_css('dialog[data-shorts-player-target="dialog"]', count: 1, visible: :all)
  end

  it 'allows opening background cards and maps every card to its playback URL' do
    render_inline(component)

    expect(page).to have_css('button[data-shorts-deck-target="item"]:not([disabled]):not([aria-hidden="true"])', count: 4)
    expect(page).to have_css('button[data-shorts-player-index-param="1"][data-video-src="/shorts/short-2/signed_url"]')
    expect(page).to have_css('button[data-shorts-deck-target="item"][hidden]', count: 1, visible: :all)
  end

  it 'renders the default preview using the existing demo streams' do
    render_preview(:default, from: Shorts::DeckPreview, params: {lookbook: {display: {}}})

    expect(page).to have_css('[data-shorts-player-target="item"]', count: 7, visible: :all)
    expect(page).to have_css('[data-video-src="/shorts/8da99b7c-f9b8-4464-846f-6635924b5e5b/signed_url"]')
  end

  context 'with one Short' do
    let(:items) { [{id: 'short-1', thumbnail: 'https://example.com/one.jpg'}] }

    it 'renders the card without browsing controls' do
      render_inline(component)

      expect(page).to have_css('[data-shorts-player-target="item"]', count: 1)
      expect(page).to have_no_css('[data-action="click->shorts-deck#previous"]')
      expect(page).to have_no_css('[data-action="click->shorts-deck#next"]')
    end
  end

  context 'with two Shorts' do
    let(:items) do
      [
        {id: 'short-1', thumbnail: 'https://example.com/one.jpg'},
        {id: 'short-2', thumbnail: 'https://example.com/two.jpg'},
      ]
    end

    it 'renders both cards and browsing controls' do
      render_inline(component)

      expect(page).to have_css('[data-shorts-player-target="item"]', count: 2)
      expect(page).to have_css('[data-action="click->shorts-deck#previous"]')
      expect(page).to have_css('[data-action="click->shorts-deck#next"]')
    end
  end

  context 'without Shorts' do
    let(:items) { [] }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('[data-controller]')
    end
  end
end
