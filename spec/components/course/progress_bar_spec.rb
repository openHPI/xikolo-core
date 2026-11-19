# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressBar, type: :component do
  it 'renders the label, percentage, and progress bar' do
    render_inline(described_class.new(percentage: 10))

    expect(page).to have_text 'Progress'
    expect(page).to have_text '10%'
    expect(page).to have_css('progress.x-progress[value="10"][max="100"][aria-labelledby="progress-label"]')
  end

  it 'renders a skeleton without a percentage' do
    render_inline(described_class.new)

    expect(page).to have_text 'Progress'
    expect(page).to have_css('.x-skeleton', count: 2)
    expect(page).to have_no_css('progress')
    expect(page).to have_no_text '%'
  end

  it 'renders an empty progress bar, not a skeleton, for no progress' do
    render_inline(described_class.new(percentage: 0))

    expect(page).to have_css('progress[value="0"]')
    expect(page).to have_text '0%'
    expect(page).to have_no_css('.x-skeleton')
  end
end
