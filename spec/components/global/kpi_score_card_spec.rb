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
  end
end
