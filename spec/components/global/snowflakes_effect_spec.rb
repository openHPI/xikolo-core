# frozen_string_literal: true

require 'spec_helper'

describe Global::SnowflakesEffect, type: :component do
  subject(:component) { described_class.new(show_on_paths: ['/home']) }

  describe '#render' do
    context 'when on a matching path' do
      before do
        vc_test_request.path = '/home'
      end

      it 'renders the snow container with snowflakes controller' do
        render_inline(component)
        expect(page).to have_css('#snow-container[aria-hidden="true"]')
        expect(page).to have_css('[data-controller="snowflakes_effect"]')
      end
    end

    context 'when render? returns false' do
      before do
        vc_test_request.path = '/other'
      end

      it 'does not render anything' do
        render_inline(component)
        expect(page).to have_no_css('#snow-container')
      end
    end
  end
end
