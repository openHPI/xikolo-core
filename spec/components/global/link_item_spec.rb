# frozen_string_literal: true

require 'spec_helper'

describe Global::LinkItem, type: :component do
  subject(:component) { described_class.new(**props) }

  describe '#render' do
    let(:props) do
      {
        text: 'This is a link!',
        href: 'http://example.com',
        title: 'Link hover titles are nice!',
      }
    end

    it 'includes a link' do
      render_inline(component)
      expect(page).to have_link('This is a link!', href: 'http://example.com')
    end

    context 'to be opened in a new tab' do
      let(:props) { super().merge(target: '_blank') }

      it 'includes a link opened in a new tab, setting noopener' do
        render_inline(component)
        expect(page).to have_css('li > a[rel="noopener"]', exact_text: 'This is a link!')
      end
    end

    context 'with icon' do
      let(:props) { super().merge(icon_class: 'plus') }

      it 'displays the icon' do
        render_inline(component)
        expect(page).to have_css('li > a > .xi-icon.fa-regular.fa-plus')
      end
    end
  end
end
