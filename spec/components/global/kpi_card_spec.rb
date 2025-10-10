# frozen_string_literal: true

require 'spec_helper'

describe Global::KpiCard, type: :component do
  subject(:component) do
    described_class.new(
      icon_class: icon_class,
      title: title,
      metrics: metrics,
      empty_message: empty_message
    )
  end

  let(:icon_class) { 'fas fa-graduation-cap' }
  let(:title) { 'Enrollments' }
  let(:metrics) do
    [
      {counter: '8', title: 'Total'},
      {counter: '+0', title: 'Last 24 hours'},
    ]
  end
  let(:empty_message) { nil }

  describe '#render' do
    it 'renders the icon, title and metrics including right-side values when present' do
      render_inline(component)

      expect(page).to have_content('Enrollments')
      expect(page).to have_content('8')
      expect(page).to have_content('Total')
      expect(page).to have_content('Last 24 hours')
    end

    context 'with quota' do
      let(:metrics) do
        [
          {counter: '5', title: 'At middle', quota_text: '5 non-deleted', quota: '100%'},
        ]
      end

      it 'renders the quota and quota_text' do
        render_inline(component)

        expect(page).to have_content('5 non-deleted')
        expect(page).to have_content('100%')
      end
    end

    context 'without metrics' do
      let(:metrics) { [] }
      let(:empty_message) { 'No metrics yet' }

      it 'renders the empty message' do
        render_inline(component)

        expect(page).to have_content('No metrics yet')
      end
    end
  end
end
