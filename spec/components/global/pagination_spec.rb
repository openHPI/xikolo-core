# frozen_string_literal: true

require 'spec_helper'

describe Global::Pagination, type: :component do
  subject(:component) { described_class.new(pagination) }

  let(:pagination) { [*(1..40)].paginate(page: 2, per_page: 10) }

  describe '#render?' do
    context 'when the collection has entries' do
      it { is_expected.to be_render }
    end

    context 'when the collection is empty' do
      let(:pagination) { [].paginate(page: 1, per_page: 10) }

      it { is_expected.not_to be_render }
    end
  end

  describe 'rendered output' do
    before do
      with_request_url '/admin/learn' do
        render_inline(component)
      end
    end

    describe 'pagination info' do
      it 'shows the correct range for the current page' do
        expect(page).to have_text('Showing 11 to 20 of 40 entries')
      end

      context 'on the last page with fewer items than per_page' do
        let(:pagination) { [*(1..35)].paginate(page: 4, per_page: 10) }

        it 'caps the upper bound at total_entries' do
          expect(page).to have_text('Showing 31 to 35 of 35 entries')
        end
      end

      context 'on the first page' do
        let(:pagination) { [*(1..40)].paginate(page: 1, per_page: 10) }

        it 'starts from 1' do
          expect(page).to have_text('Showing 1 to 10 of 40 entries')
        end
      end
    end

    context 'when there are fewer entries than per_page' do
      let(:pagination) { [*(1..5)].paginate(page: 1, per_page: 10) }

      it 'renders the pagination info' do
        expect(page).to have_text('Showing 1 to 5 of 5 entries')
      end

      it 'does not render the pagination controls' do
        expect(page).to have_no_css('[aria-label="Pagination"]')
      end
    end
  end
end
