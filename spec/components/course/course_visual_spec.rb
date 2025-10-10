# frozen_string_literal: true

require 'spec_helper'

describe Course::CourseVisual, type: :component do
  subject(:component) do
    described_class.new url, width: 50, alt_text: 'CSS Course'
  end

  context 'when an image is given' do
    let(:url) { 'https://s3.example.com/courses/css.png' }

    it 'renders the given image' do
      render_inline(component)
      expect(page).to have_css 'img[src="https://s3.example.com/courses/css.png"]'
    end

    it 'sets the alternative text for the image' do
      render_inline(component)
      expect(page).to have_css 'img[alt="CSS Course"]'
    end

    context 'with specific width requirement' do
      before do
        allow(Imagecrop).to receive(:enabled?).and_return(true)
        allow(Imagecrop).to receive(:transform) {|source, _| source }
        allow(Imagecrop).to receive(:transform)
          .with('https://s3.example.com/courses/css.png', {width: 50})
          .and_return('https://www.example.com/50/css.png')
      end

      it 'applies custom CSS' do
        render_inline(component)
        expect(page).to have_css 'img[src="https://www.example.com/50/css.png"]'
      end
    end
  end

  context 'when no image is given' do
    let(:url) { nil }

    it 'falls back to a default image' do
      render_inline(component)
      expect(page).to have_css 'img[src*="defaults/course"]'
    end
  end

  context 'with custom CSS modifier' do
    subject(:component) do
      described_class.new url, css_classes: 'custom-class'
    end

    let(:url) { 'https://s3.example.com/courses/css.png' }

    it 'applies custom CSS' do
      render_inline(component)
      expect(page).to have_css 'img[class="custom-class"]'
    end
  end
end
