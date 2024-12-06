# frozen_string_literal: true

require 'spec_helper'

describe Global::FilterBar::Filter, type: :component do
  subject(:component) do
    described_class.new(key, title, options, selected:, visible:)
  end

  let(:key) { 'filter_key' }
  let(:title) { 'Filter label' }
  let(:options) { %w[A B C] }
  let(:selected) { nil }
  let(:visible) { true }

  context 'in the default state' do
    it 'allows selecting between options' do
      render_inline(component)

      expect(rendered_content).to have_select 'Filter label', with_options: %w[A B C]
    end
  end

  context 'as non-visible filter' do
    let(:visible) { false }

    it 'does not show' do
      render_inline(component)

      expect(rendered_content).to have_no_text 'Filter label'
    end

    context 'with an option selected' do
      let(:selected) { 'A' }

      it 'shows as plain text' do
        render_inline(component)

        expect(rendered_content).to have_no_select 'Filter label'
        expect(rendered_content).to have_text 'Filter label'
        expect(rendered_content).to have_text 'A'
      end

      context 'and the options have a title' do
        let(:options) { {'Alfa' => 'A', 'Beta' => 'B', 'Charlie' => 'C'} }

        it 'shows the title from the selected value' do
          render_inline(component)

          expect(rendered_content).to have_text 'Alfa'
        end

        context 'but the selected option is not available' do
          let(:options) { {'Beta' => 'B', 'Charlie' => 'C'} }

          it 'shows the selected value' do
            render_inline(component)

            expect(rendered_content).to have_text 'A'
          end
        end
      end
    end
  end
end
