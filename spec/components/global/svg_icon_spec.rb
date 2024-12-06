# frozen_string_literal: true

require 'spec_helper'

describe Global::SvgIcon, type: :component do
  subject(:component) do
    described_class.new(
      Rails.root.join('spec', 'fixtures', 'files', 'images', 'question.svg'),
      wrapping_class: 'test-svg'
    )
  end

  describe '#render' do
    before { render_inline(component) }

    it { expect(page).to have_css 'span.test-svg' }
    it { expect(page).to have_css 'svg' }
  end
end
