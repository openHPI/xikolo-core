# frozen_string_literal: true

require 'spec_helper'

describe Course::LearnerProgress::Header, type: :component do
  subject(:component) { described_class.new(progress:, **options) }

  let(:progress) { instance_double(Course::CompletedItemsProgress, completed: 20, total: 95, percentage: 21) }
  let(:options) { {} }

  it 'shows the title and the completed content' do
    render_inline(component)

    expect(page).to have_css 'h2', text: 'My learning progress'
    expect(page).to have_text 'Completed content'
    expect(page).to have_text '20 / 95'
    expect(page).to have_text '21%'
    expect(page).to have_css 'progress.x-progress[value="21"][max="100"][aria-labelledby="progress-header-label"]'
  end

  it 'does not link to the certificates without a URL' do
    render_inline(component)

    expect(page).to have_no_link 'Download certificates'
  end

  context 'with a certificates URL' do
    let(:options) { {certificates_url: '#progress-certificates-title'} }

    it 'links to the certificates' do
      render_inline(component)

      expect(page).to have_link 'Download certificates', href: '#progress-certificates-title'
    end
  end

  context 'without any progress' do
    let(:progress) { instance_double(Course::CompletedItemsProgress, completed: 0, total: 95, percentage: 0) }

    it 'shows an empty progress bar' do
      render_inline(component)

      expect(page).to have_text '0 / 95'
      expect(page).to have_text '0%'
      expect(page).to have_css 'progress[value="0"]'
    end
  end
end
