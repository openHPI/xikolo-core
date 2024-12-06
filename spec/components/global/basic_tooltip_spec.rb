# frozen_string_literal: true

require 'spec_helper'

describe Global::BasicTooltip, type: :component do
  subject(:component) { described_class.new(tooltip) }

  let(:tooltip) { 'I am a helpful tooltip!' }

  describe '#render' do
    it 'includes tooltip' do
      render_inline(component)
      expect(page).to have_css '.basic-tooltip-text', exact_text: 'I am a helpful tooltip!'
    end

    context 'with an array of tooltips' do
      let(:tooltip) { ['I am a helpful tooltip!', 'I am another tooltip.', 'Hi, I am helpful as well.'] }

      it 'includes all tooltips' do
        render_inline(component)
        expect(page).to have_css '.basic-tooltip-text',
          exact_text: 'I am a helpful tooltip!I am another tooltip.Hi, I am helpful as well.' # the <p> tags are stripped
      end
    end
  end
end
