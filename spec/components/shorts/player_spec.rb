# frozen_string_literal: true

require 'spec_helper'

describe Shorts::Player, type: :component do
  it 'renders the shared playback dialog and its controls' do
    render_inline(described_class.new)

    expect(page).to have_css('dialog[data-action="close->shorts-player#close"]', visible: :all)
    expect(page).to have_css('hlsjs-video[data-shorts-player-target="video"][loop][playsinline][disablepictureinpicture]', visible: :all)
    expect(page).to have_css('[data-action="click->shorts-player#previousVideo"]', visible: :all)
    expect(page).to have_css('[data-action="click->shorts-player#nextVideo"]', visible: :all)
    expect(page).to have_css('form[method="dialog"]', count: 2, visible: :all)
  end
end
