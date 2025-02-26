# frozen_string_literal: true

require 'spec_helper'

describe Util::RelativeTimeTag, type: :component do
  subject(:component) { described_class.new(time) }

  let(:time) { DateTime.now }

  describe '#render' do
    it 'renders the relative time tag' do
      render_inline(component)
      expect(page).to have_css('relative-time')
    end
  end
end
