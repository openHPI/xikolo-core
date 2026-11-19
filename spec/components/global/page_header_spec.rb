# frozen_string_literal: true

require 'spec_helper'

describe Global::PageHeader, type: :component do
  subject(:component) { described_class.new(title, lang:, subtitle:, breadcrumbs:, back_url:, type:) }

  let(:title) { 'Quantencomputing Summer School' }
  let(:breadcrumbs) { [] }
  let(:subtitle) { nil }
  let(:back_url) { nil }
  let(:lang) { nil }
  let(:type) { nil }

  it 'renders the title as the page heading' do
    render_inline(component)

    expect(page).to have_css('h1', text: 'Quantencomputing Summer School')
  end

  it 'renders at the larger title size by default' do
    render_inline(component)

    expect(page).to have_css('h1.sm\\:text-3xl')
  end

  context 'with the slim type' do
    let(:type) { :slim }

    it 'renders the smaller title' do
      render_inline(component)

      expect(page).to have_css('h1.sm\\:text-lg')
    end
  end

  context 'with a subtitle' do
    let(:subtitle) { 'Platform administration' }

    it 'renders it below the title' do
      render_inline(component)

      expect(page).to have_text 'Platform administration'
    end
  end

  context 'with a language' do
    let(:lang) { 'de' }

    it 'marks up the title language' do
      render_inline(component)

      expect(page).to have_css("[lang='de']", text: 'Quantencomputing Summer School')
    end
  end

  context 'without a language' do
    it 'omits the attribute' do
      render_inline(component)

      expect(page).to have_no_css('[lang]')
    end
  end

  context 'with breadcrumbs' do
    let(:breadcrumbs) { [{url: '/learn', text: 'Learn'}, {url: '/learn/quantum', text: title}] }

    it 'renders the trail' do
      render_inline(component)

      expect(page).to have_link('Learn', href: '/learn')
      expect(page).to have_link('Quantencomputing Summer School', href: '/learn/quantum')
    end
  end

  context 'without breadcrumbs' do
    it 'renders no trail' do
      render_inline(component)

      expect(page).to have_no_css('nav.x-breadcrumbs')
    end
  end

  context 'with a back url' do
    let(:back_url) { '/learn/quantum' }

    it 'links back to the course' do
      render_inline(component)

      expect(page).to have_link(I18n.t('components.page_header.back_to_course'), href: '/learn/quantum')
    end
  end

  context 'without a back url' do
    it 'omits the back link' do
      render_inline(component)

      expect(page).to have_no_link(I18n.t('components.page_header.back_to_course'))
    end
  end

  context 'with an item header' do
    it 'renders below the title as the h1' do
      render_inline(component) do |header|
        header.with_item_header { '<h1>Titel Video</h1>'.html_safe }
      end

      expect(page).to have_css('h1', text: 'Titel Video')
      expect(page).to have_no_css('h1', text: 'Quantencomputing Summer School')
    end
  end

  context 'with navigation' do
    subject(:rendered) do
      render_inline(component) do |header|
        header.with_navigation { '<nav><a href="/forum">Forum</a></nav>'.html_safe }
      end
    end

    it 'renders the navigation' do
      rendered

      expect(page).to have_link 'Forum', href: '/forum'
    end

    it 'keeps the title as a visually hidden page heading' do
      rendered

      expect(page).to have_css('h1.sr-only', text: 'Quantencomputing Summer School', visible: :all)
    end

    it 'uses the light accent background' do
      rendered

      expect(page).to have_css("header[class*='--page-header-bg:var(--color-accent-25)']")
    end
  end

  context 'with additional content' do
    it 'renders it below the title' do
      render_inline(component) { '<a href="/about">More information</a>'.html_safe }

      expect(page).to have_link 'More information', href: '/about'
    end
  end
end
