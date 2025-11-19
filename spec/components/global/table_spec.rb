# frozen_string_literal: true

require 'spec_helper'

describe Global::Table, type: :component do
  subject(:component) { described_class.new(rows:, headers:, title:) }

  let(:rows) { [{name: 'John', age: 25}, {name: 'Jane', age: 30}] }
  let(:headers) { %w[Name Age] }
  let(:title) { 'User List' }

  describe '#render' do
    it 'renders the table with title' do
      render_inline(component)
      expect(page).to have_text('User List')
    end

    it 'renders table headers' do
      render_inline(component)
      expect(page).to have_text('Name')
      expect(page).to have_text('Age')
    end

    it 'renders table rows' do
      render_inline(component)
      expect(page).to have_text('John')
      expect(page).to have_text('25')
    end

    context 'with empty rows' do
      let(:rows) { [] }

      it 'shows empty state component' do
        render_inline(component)
        expect(page).to have_text('No data available')
      end
    end

    context 'with caption' do
      subject(:component) { described_class.new(rows:, headers:, title:, caption: 'Test caption') }

      it 'renders the caption' do
        render_inline(component)
        expect(page).to have_text('Test caption')
      end
    end
  end
end
