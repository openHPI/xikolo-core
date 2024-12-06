# frozen_string_literal: true

require 'spec_helper'

describe Global::FlashBlock, type: :component do
  subject(:component) { described_class.new flash_mock }

  let(:flash_mock) { {notice: flash_notice} }
  let(:flash_notice) { [] }

  describe '#render' do
    context 'with duplicate message' do
      let(:flash_notice) { %w[test test] }

      it 'eliminates duplicate messages' do
        render_inline(component)
        expect(page).to have_css('[role=status][aria-live=polite]', count: 1)
      end
    end
  end
end
