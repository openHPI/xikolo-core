# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Items::ContentCard, type: :component do
  subject(:component) { described_class.new(rendered_content: content, lang: 'en', title:) }

  let(:content) { '<p>Rendered <strong>content</strong></p>' }
  let(:title) { nil }

  it 'renders content in a DaisyUI card' do
    render_inline(component)

    expect(page).to have_css('article.x-card > .x-card-body')
    expect(page).to have_css('.prose[lang="en"] strong', text: 'content')
  end

  context 'with a title' do
    let(:title) { 'About this video' }

    it 'renders the title' do
      render_inline(component)

      expect(page).to have_css('h4.x-card-title', text: 'About this video')
    end
  end
end
