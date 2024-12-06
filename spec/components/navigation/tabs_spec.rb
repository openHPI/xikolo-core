# frozen_string_literal: true

require 'spec_helper'

describe Navigation::Tabs, type: :component do
  subject(:component) { described_class.new(collapsible:) }

  let(:collapsible) { nil }

  describe 'expandable behavior' do
    context 'per default' do
      it 'there is no button to expand the navigation' do
        render_inline(component)

        expect(page).to have_css("[data-controller='navigation-tabs']")
        expect(page).to have_no_css("button[aria-label='Show navigation']")
      end
    end

    context 'with expandible configuration' do
      let(:collapsible) { true }

      it 'has a button to expand the navigation' do
        render_inline(component)

        expect(page).to have_css("button[aria-label='Show navigation']")
      end
    end
  end

  describe 'with tabs provided' do
    it 'renders the tabs in a list' do
      render_inline(component) do |c|
        c.with_tab { '<a href=#>A link</a>'.html_safe }
      end

      expect(page).to have_css('ul[role=tablist]', count: 1)
      expect(page).to have_css('li', count: 1)
      expect(page).to have_css('[role=tab]', count: 1)
      expect(page).to have_link('A link', href: '#')
    end

    context 'with an active tab' do
      it 'renders a class that marks it active' do
        render_inline(component) do |c|
          c.with_tab(active: true) { '<a href=#>A link</a>'.html_safe }
        end

        expect(page).to have_css('.navigation-tabs__item--active')
      end
    end
  end

  describe 'with additional items present' do
    it 'renders them in a separate list' do
      render_inline(component) do |c|
        c.with_tab { '<a href=#>A link</a>'.html_safe }
        c.with_additional_item { '<a href=#>Additional Item</a>'.html_safe }
      end

      # There is only one tablist
      # because the additional items do not have a special role
      expect(page).to have_css('ul[role=tablist]', count: 1)
      expect(page).to have_css('ul', count: 2)

      expect(page).to have_css('li', count: 2)
      expect(page).to have_link('A link', href: '#')
    end
  end

  describe 'with panels' do
    it 'shows only active panels' do
      render_inline(component) do |c|
        c.with_tab(controls: 'panel-force-one', active: true) { '<button type="button">Tab 1</button>'.html_safe }
        c.with_tab(controls: 'panel-force-two') { '<button type="button">Tab 2</button>'.html_safe }
        c.with_panel(id: 'panel-force-one', active: true) { '<p>Content 1</p>'.html_safe }
        c.with_panel(id: 'panel-force-two') { '<p>Content 2</p>'.html_safe }
      end

      expect(page).to have_button('Tab 1')
      expect(page).to have_button('Tab 2')
      expect(page).to have_css('[role=tab]', count: 2)

      expect(page).to have_css('div[role=tabpanel]', count: 1)
      expect(page).to have_text('Content 1')
    end
  end
end
