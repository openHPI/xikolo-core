# frozen_string_literal: true

require 'spec_helper'

describe Global::KpiScoreCard, type: :component do
  subject(:component) do
    described_class.new(
      title: title,
      value: value,
      icon_class: icon_class,
      more_details_url: more_details_url
    )
  end

  let(:title) { 'Test Score' }
  let(:value) { '123' }
  let(:icon_class) { 'fas fa-eye' }
  let(:more_details_url) { '/test' }

  describe '#formatted_value' do
    it 'formats count values with delimiters' do
      component = described_class.new(title: 'Test', value: 1234, icon_class: 'eye')
      render_inline(component)
      expect(page).to have_content('1,234')
    end

    it 'formats percentage values' do
      component = described_class.new(title: 'Test', value: 0.8567, icon_class: 'eye', format: :percentage)
      render_inline(component)
      expect(page).to have_content('85.67%')
    end

    it 'returns n/a for blank values' do
      component = described_class.new(title: 'Test', value: nil, icon_class: 'eye')
      render_inline(component)
      expect(page).to have_content('n/a')
    end
  end

  describe '#render' do
    it 'renders title, value and more details link' do
      render_inline(component)
      expect(page).to have_content('Test Score')
      expect(page).to have_content('123')
      expect(page).to have_link('More details', href: '/test')
    end

    context 'when url is nil' do
      let(:more_details_url) { nil }

      it 'omits the more details link' do
        render_inline(component)
        expect(page).to have_content('Test Score')
        expect(page).to have_content('123')
        expect(page).to have_no_link('More details')
      end
    end

    it 'renders percentage format correctly' do
      component = described_class.new(title: 'Quiz Performance', value: 0.75, icon_class: 'user-edit', format: :percentage)
      render_inline(component)
      expect(page).to have_content('75.00%')
    end
  end
end
