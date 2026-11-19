# frozen_string_literal: true

require 'spec_helper'

describe Global::FilterBar::Form, type: :component do
  subject(:rendered) do
    with_request_url request_url do
      render_inline described_class.new(action: '/learn', filters:, search_param: :autocomplete) do |form|
        form.with_controls(**controls_options)
      end
    end
  end

  let(:request_url) { '/learn?autocomplete=Ruby' }
  let(:filters) { [] }
  let(:controls_options) { {content_id: '#results', loading_indicator_id: '#loading'} }

  it 'offers a reset link for the current search' do
    expect(rendered).to have_field 'Search', with: 'Ruby'
    expect(rendered).to have_link 'Reset all filters', href: '/learn'
  end

  context 'without loading indicators' do
    let(:controls_options) { {} }

    it 'offers the same reset link' do
      expect(rendered).to have_link 'Reset all filters', href: '/learn'
    end
  end

  context 'with an active filter and no search' do
    let(:request_url) { '/learn' }
    let(:filters) { [Global::FilterBar::Filter.new(:status, 'Status', %w[active inactive], selected: 'active')] }

    it 'offers a reset link for the selected filter' do
      expect(rendered).to have_select 'Status', selected: 'active'
      expect(rendered).to have_link 'Reset all filters', href: '/learn'
    end
  end
end
