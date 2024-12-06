# frozen_string_literal: true

require 'spec_helper'

describe Global::HeadlineTooltip, type: :component do
  subject(:component) { described_class.new('Headline with Tooltip', level: 2) }

  describe '#render' do
    it 'includes headline with correct level' do
      render_inline(component)
      expect(page).to have_css 'h2', exact_text: 'Headline with Tooltip'
    end
  end
end
