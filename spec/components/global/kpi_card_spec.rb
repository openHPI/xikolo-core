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

      expect(page).to have_text('Enrollments')
      expect(page).to have_text('8')
      expect(page).to have_text('Total')
      expect(page).to have_text('Last 24 hours')
    end

    context 'with quota' do
      let(:metrics) do
        [
          {counter: '5', title: 'At middle', quota_text: '5 non-deleted', quota: '100%'},
        ]
      end

      it 'renders the quota and quota_text' do
        render_inline(component)

        expect(page).to have_text('5 non-deleted')
        expect(page).to have_text('100%')
      end

      context 'with certificate data' do
        let(:metrics) do
          [
            {counter: '223', title: 'Records of Achievement', quota: '0%', quota_text: 'ratio based on shows at middle'},
            {counter: '128', title: 'Confirmations of Participation', quota: '0%', quota_text: 'ratio based on all shows'},
          ]
        end

        it 'show the correct certificate metrics' do
          render_inline(component)

          expect(page).to have_text('Records of Achievement')
          expect(page).to have_text('223')
          expect(page).to have_text('Confirmations of Participation')
          expect(page).to have_text('128')
        end
      end
    end

    context 'without metrics' do
      let(:metrics) { [] }
      let(:empty_message) { 'No metrics yet' }

      it 'renders the empty message' do
        render_inline(component)

        expect(page).to have_text('No metrics yet')
      end
    end
  end
end
