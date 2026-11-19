# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Items::Header, type: :component do
  subject(:component) do
    described_class.new(title:, icon_class: 'video', section_title:)
  end

  let(:title) { 'Willkommen zum Kurs Digitale Gerechtigkeit' }
  let(:section_title) { 'Module 1' }

  it 'renders the item title as the main heading' do
    render_inline(component)

    expect(page).to have_text('Willkommen zum Kurs Digitale Gerechtigkeit')
  end

  it 'renders the section title' do
    render_inline(component)

    expect(page).to have_text('Module 1')
  end

  it 'renders the item type icon in a circle' do
    render_inline(component)

    expect(page).to have_css('span.rounded-full[aria-hidden="true"]')
  end

  it 'limits the item title to two lines' do
    render_inline(component)

    expect(page).to have_css('h1.line-clamp-2')
  end

  context 'with actions' do
    it 'renders them next to the title' do
      render_inline(component) do |c|
        c.with_action { '<a href="/edit">Edit item</a>'.html_safe }
        c.with_action { '<a href="/stats">Statistics</a>'.html_safe }
      end

      expect(page).to have_link('Edit item', href: '/edit')
      expect(page).to have_link('Statistics', href: '/stats')
    end
  end

  context 'without actions' do
    it 'renders no action container' do
      render_inline(component)

      expect(page).to have_no_link
    end
  end

  context 'with a language' do
    subject(:component) do
      described_class.new(title:, icon_class: 'video', section_title:, lang: 'de')
    end

    it 'marks up the title language' do
      render_inline(component)

      expect(page).to have_css('h1[lang="de"]')
    end
  end

  context 'without a language' do
    it 'omits the attribute' do
      render_inline(component)

      expect(page).to have_no_css('h1[lang]')
    end
  end

  context 'without a section title' do
    let(:section_title) { nil }

    it 'only renders the item title' do
      render_inline(component)

      expect(page).to have_text('Willkommen zum Kurs Digitale Gerechtigkeit')
      expect(page).to have_no_text('Module 1')
    end
  end
end
