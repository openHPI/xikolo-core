# frozen_string_literal: true

require 'spec_helper'

describe Course::CertificateCard, type: :component do
  subject(:component) do
    described_class.new(
      title: 'Certificate',
      description: 'You did not score enough points in graded exams, yet.',
      requirement: 'Achieve 50% of the overall score in graded assignments.',
      issued_on: '—',
      **options
    )
  end

  let(:options) { {} }

  it 'shows the certificate details' do
    render_inline(component)

    expect(page).to have_css 'h3', text: 'Certificate'
    expect(page).to have_text 'You did not score enough points in graded exams, yet.'
    expect(page).to have_css 'dd', text: 'Achieve 50% of the overall score in graded assignments.'
    expect(page).to have_css 'dd', text: '—'
  end

  it 'is pending and cannot be downloaded by default' do
    render_inline(component)

    expect(page).to have_css '.x-badge', text: 'Pending'
    expect(page).to have_button 'Download', disabled: true
    expect(page).to have_no_link
  end

  context 'when achieved and downloadable' do
    let(:options) { {achieved: true, download_path: '/certificate/render?type=RecordOfAchievement'} }

    it 'offers the download' do
      render_inline(component)

      expect(page).to have_css '.x-badge', text: 'Achieved'
      expect(page).to have_link 'Download', href: '/certificate/render?type=RecordOfAchievement'
    end
  end

  context 'when achieved without a download' do
    let(:options) { {achieved: true} }

    it 'disables the download' do
      render_inline(component)

      expect(page).to have_css '.x-badge', text: 'Achieved'
      expect(page).to have_button 'Download', disabled: true
    end
  end
end
