# frozen_string_literal: true

require 'spec_helper'

describe Global::Table, type: :component do
  subject(:component) { described_class.new(data:, headers:, title:) }

  let(:data) { [{name: 'John', age: 25}, {name: 'Jane', age: 30}] }
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

    it 'renders table data' do
      render_inline(component)
      expect(page).to have_text('John')
      expect(page).to have_text('25')
    end

    context 'with empty data' do
      let(:data) { [] }

      it 'shows empty state component' do
        render_inline(component)
        expect(page).to have_text('No data available')
      end
    end
  end
end
