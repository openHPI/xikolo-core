# frozen_string_literal: true

require 'spec_helper'

describe Course::BottomNavigation, type: :component do
  subject(:component) { described_class.new(**links) }

  let(:previous_link) { {url: '/learn/example/items/previous', title: 'Introduction', icon: 'video'} }
  let(:next_link) { {url: '/learn/example/items/next', title: 'Practice', icon: 'text'} }

  context 'with a next link only' do
    let(:links) { {next_link:} }

    it 'renders the supplied destination, title, and icon' do
      render_inline(component)

      expect(page).to have_link('Next', href: next_link[:url])
      expect(page).to have_css('a[aria-label="Next: Practice"]')
      expect(page).to have_css('svg', count: 2)
      expect(page).to have_no_link('Previous')
    end
  end

  context 'with both links' do
    let(:links) { {previous_link:, next_link:} }

    it 'renders both destinations with direction-specific labels' do
      render_inline(component)

      expect(page).to have_link('Previous', href: previous_link[:url])
      expect(page).to have_link('Next', href: next_link[:url])
      expect(page).to have_css('a[aria-label="Previous: Introduction"]')
    end
  end

  context 'with a previous link only' do
    let(:links) { {previous_link:} }

    it 'renders the previous destination only' do
      render_inline(component)

      expect(page).to have_link('Previous', href: previous_link[:url])
      expect(page).to have_no_link('Next')
    end
  end

  context 'without links' do
    let(:links) { {} }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('a')
      expect(component.render?).to be false
    end
  end

  context 'with section links' do
    let(:links) { {previous_link: previous_link.merge(section: true), next_link: next_link.merge(section: true)} }

    it 'uses the module labels for both directions' do
      render_inline(component)

      expect(page).to have_link(I18n.t('items.show.prev_section_item'), href: previous_link[:url])
      expect(page).to have_link(I18n.t('items.show.next_section_item'), href: next_link[:url])
    end
  end
end
