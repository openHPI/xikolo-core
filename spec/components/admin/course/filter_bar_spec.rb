# frozen_string_literal: true

require 'spec_helper'

describe Admin::Course::FilterBar, type: :component do
  subject(:rendered) { render_inline described_class.new }

  it 'allows filtering by course status' do
    expect(rendered).to have_select 'Status', with_options: %w[All Preparation Active Archive]
  end

  it 'allows searching courses' do
    expect(rendered).to have_field 'Search', type: 'search'
  end
end
