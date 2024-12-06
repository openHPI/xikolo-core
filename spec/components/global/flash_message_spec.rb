# frozen_string_literal: true

require 'spec_helper'

describe Global::FlashMessage, type: :component do
  subject(:component) { described_class.new :notice, 'Click <a href="#">here</a>.' }

  describe '#render' do
    it 'includes unescaped flash message' do
      render_inline(component)
      expect(page).to have_link 'here', href: '#'
    end

    it 'wraps the alert text in semantic markup' do
      render_inline(component)
      expect(page).to have_css '[role=status][aria-live=polite]', text: 'Click here'
    end
  end
end
