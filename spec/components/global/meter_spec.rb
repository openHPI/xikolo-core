# frozen_string_literal: true

require 'spec_helper'

describe Global::Meter, type: :component do
  subject(:component) { described_class.new(value:) }

  let(:value) { 100 };

  describe '#render' do
    it 'includes a meter with the configured value' do
      render_inline(component)
      expect(page).to have_css("meter[value='100']")
    end

    context 'with a label' do
      subject(:component) { described_class.new(value:, label: 'Label') }

      it 'includes the label' do
        render_inline(component)
        expect(page).to have_text('Label')
      end
    end

    context 'with type info' do
      subject(:component) { described_class.new(value:, label: 'Label', type: :info) }

      it 'includes a class for styling' do
        render_inline(component)
        expect(page).to have_css('.meter--info')
      end
    end
  end
end
