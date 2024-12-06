# frozen_string_literal: true

require 'spec_helper'

describe Navigation::Item, type: :component do
  subject(:component) do
    described_class.new(text:, link:, icon:, active:, locked:, tooltip:)
  end

  let(:text) { 'Item' }
  let(:link) { {href:, target:} }
  let(:href) { '/' }
  let(:target) { nil }
  let(:icon) { {} }
  let(:active) { false }
  let(:locked) { false }
  let(:tooltip) { nil }

  describe '#active?' do
    it 'can be set explicitly' do
      component = described_class.new(text:, active: false)
      expect(component.active?).to be false

      component = described_class.new(text:, active: true)
      expect(component.active?).to be true
    end

    it 'is false by default' do
      component = described_class.new(text:)
      expect(component.active?).to be false
    end

    it 'checks whether any of the children are active' do
      component = described_class.new(text:).tap do |c|
        c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'}, active: false)
        c.with_item described_class.new(text: 'Sub-Item 2', link: {href: '/'}, active: false)
      end

      expect(component.active?).to be false

      component = described_class.new(text:).tap do |c|
        c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'}, active: true)
        c.with_item described_class.new(text: 'Sub-Item 2', link: {href: '/'}, active: false)
      end

      expect(component.active?).to be true
    end

    it 'can recursively check for active children' do
      component = described_class.new(text:).tap do |c|
        c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'})
        c.with_item(described_class.new(text: 'Sub-Item 2').tap do |nested|
          nested.with_item described_class.new(text: 'Nested', link: {href: '/'}, active: false)
        end)
      end

      expect(component.active?).to be false

      component = described_class.new(text:).tap do |c|
        c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'})
        c.with_item(described_class.new(text: 'Sub-Item 2').tap do |nested|
          nested.with_item described_class.new(text: 'Nested', link: {href: '/'}, active: true)
        end)
      end

      expect(component.active?).to be true
    end

    it "allows explicitly overriding the children's active state" do
      component = described_class.new(text:, active: false).tap do |c|
        c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'}, active: true)
        c.with_item described_class.new(text: 'Sub-Item 2', link: {href: '/'})
      end

      expect(component.active?).to be false
    end
  end

  describe 'main navigation item' do
    context 'without a dropdown menu' do
      it 'displays the text and links to the given path' do
        render_inline(component)

        expect(page).to have_link 'Item', href: '/'
        expect(page).to have_no_css '[aria-current]'
      end

      context 'with link set to open in a new tab' do
        let(:target) { '_blank' }

        it 'opens in a (secured) new tab' do
          render_inline(component)

          expect(page).to have_css 'a[href="/"][target=_blank][rel=noopener]'
          expect(page).to have_no_css '[aria-current]'
        end
      end

      context 'with icon only' do
        let(:text) { nil }
        let(:icon) { {code: 'globe'} }

        it 'links to the given path and displays the icon' do
          render_inline(component)

          expect(page).to have_link '', href: '/'
          expect(page).to have_css '.fa-globe'
        end

        context 'with aria-label' do
          let(:icon) { {code: 'globe', aria_label: 'choose language'} }

          it 'links to the given path and displays the icon and its aria-label' do
            render_inline(component)
            expect(page).to have_link '', href: '/'
            expect(page).to have_css '.fa-globe'
            expect(page).to have_css '[aria-label="choose language"]'
          end
        end
      end

      context 'without a link' do
        let(:link) { nil }

        it 'does not render an anchor tag' do
          render_inline(component)

          expect(page).to have_no_link 'Item', href: '/'
          expect(page).to have_text 'Item'
        end
      end

      context 'with text and icon' do
        let(:icon) { {code: 'globe'} }

        it 'links to the given path and displays the text and icon' do
          render_inline(component)

          expect(page).to have_link 'Item', href: '/'
          expect(page).to have_css '.fa-globe'
        end
      end

      context 'in locked state' do
        let(:locked) { true }

        it 'displays the lock icon' do
          render_inline(component)
          expect(page).to have_css '.fa-lock'
        end
      end

      context 'with tooltip' do
        let(:tooltip) { 'This is a tooltip' }

        it 'displays the tooltip' do
          render_inline(component)
          expect(page).to have_css '[data-tooltip="This is a tooltip"][aria-label="This is a tooltip"]'
        end
      end

      context 'in its active state' do
        let(:active) { true }

        it 'highlights the current page' do
          render_inline(component)
          expect(page).to have_css '[aria-current="page"]'
        end
      end
    end

    context 'with a dropdown menu' do
      it 'displays the dropdown menu' do
        render_inline(component) do |c|
          c.with_item text: 'Sub-Item 1', link: {href: '/'}
          c.with_item text: 'Sub-Item 2', link: {href: '/'}
        end
        expect(page).to have_content 'Sub-Item 1'
        expect(page).to have_no_link 'Item', href: '/', exact: true
        expect(page).to have_link 'Sub-Item 1'
        expect(page).to have_link 'Sub-Item 2'
        expect(page).to have_css '.navigation-item__control--on-collapsed'
        expect(page).to have_no_css '.navigation-item__main--active'
      end

      context 'defined with component instances' do
        it 'displays the dropdown menu' do
          render_inline(component) do |c|
            c.with_item described_class.new(text: 'Sub-Item 1', link: {href: '/'})
            c.with_item described_class.new(text: 'Sub-Item 2', link: {href: '/'})
          end
          expect(page).to have_content 'Sub-Item 1'
          expect(page).to have_no_link 'Item', href: '/', exact: true
          expect(page).to have_link 'Sub-Item 1'
          expect(page).to have_link 'Sub-Item 2'
          expect(page).to have_css '.navigation-item__control--on-collapsed'
          expect(page).to have_no_css '.navigation-item__main--active'
        end
      end

      context 'with text and icon' do
        let(:icon) { {code: 'globe', aria_label: 'Choose language'} }

        it 'displays the text and the icon but does not have the class that displays the chevron icon' do
          render_inline(component) do |c|
            c.with_item text: 'Sub-Item 1', link: {href: '/'}
            c.with_item text: 'Sub-Item 2', link: {href: '/'}
          end

          expect(page).to have_no_link 'Item', href: '/', exact: true
          expect(page).to have_link 'Sub-Item 1'
          expect(page).to have_link 'Sub-Item 2'
          expect(page).to have_css '[aria-description="Choose language"]'
          expect(page).to have_no_selector '.navigation-item__control--on-collapsed'
        end
      end

      context 'in its active state' do
        let(:active) { true }

        it 'highlights the current page' do
          render_inline(component)
          expect(page).to have_css '.navigation-item__main--active'
        end
      end
    end

    context 'with nested dropdowns' do
      it 'displays all nested items and icons to display them' do
        render_inline(component) do |c|
          c.with_item text: 'Sub-Item 1', link: {href: '/'} do |a|
            a.with_item text: 'Sub-Item 1.1', link: {href: '/'}
            a.with_item text: 'Sub-Item 1.2', link: {href: '/'}
          end
          c.with_item text: 'Sub-Item 2', link: {href: '/'} do |b|
            b.with_item text: 'Sub-Item 2.1', link: {href: '/'}
            b.with_item text: 'Sub-Item 2.2', link: {href: '/'}
          end
        end

        expect(page).to have_no_link 'Item', href: '/', exact: true

        expect(page).to have_link 'Sub-Item 1.1'
        expect(page).to have_link 'Sub-Item 1.2'

        expect(page).to have_link 'Sub-Item 2.1'
        expect(page).to have_link 'Sub-Item 2.2'

        expect(page).to have_css('.navigation-item__control--on-collapsed', count: 3)
      end
    end
  end
end
