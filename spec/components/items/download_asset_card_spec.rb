# frozen_string_literal: true

require 'spec_helper'

describe Items::DownloadAssetCard, type: :component do
  subject(:component) do
    described_class.new(
      title: title,
      url: url,
      file_type: file_type,
      size: size
    )
  end

  let(:title) { 'Course Slides' }
  let(:url) { 'https://example.com/slides.pdf' }
  let(:file_type) { 'pdf' }
  let(:size) { 3_145_728 }

  describe '#render' do
    context 'when all metadata is present' do
      before { render_inline(component) }

      it 'renders the component' do
        expect(page).to have_text(title)
        expect(page).to have_text('.pdf | 3 MB')
        expect(page).to have_link(href: url, download: true)
      end
    end

    context 'when only the file type is present' do
      let(:size) { nil }

      before { render_inline(component) }

      it 'renders the file type without a separator' do
        expect(page).to have_text('.pdf')
        expect(page).to have_no_text('|')
      end
    end

    context 'when only the size is present' do
      let(:file_type) { nil }

      before { render_inline(component) }

      it 'renders the size without a separator' do
        expect(page).to have_text('3 MB')
        expect(page).to have_no_text('|')
      end
    end

    context 'when no metadata is present' do
      let(:file_type) { nil }
      let(:size) { nil }

      before { render_inline(component) }

      it 'does not render any metadata text' do
        expect(page).to have_no_text('|')
        expect(page).to have_no_text('MB')
        expect(page).to have_no_text('.pdf')
      end
    end
  end
end
