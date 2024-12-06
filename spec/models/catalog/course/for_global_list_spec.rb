# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.for_global_list', type: :model do
  subject(:scope) { described_class.for_global_list }

  before do
    create(:course, :preparing, title: 'An upcoming course in preparation')
    create(:course, :active, title: 'An active and current course')
    create(:course, :active, title: 'An active and current but not listed course', show_on_list: false)
    create(:course, :active, :hidden, title: 'A hidden course')
    create(:course, :active, :deleted, title: 'A deleted course')
    create(:course, :active, title: 'A group-restricted course', groups: %w[group.1])
    create(:course, :archived, title: 'An archived course')
    create(:course, :archived, title: 'An archived but not listed courses', show_on_list: false)
    create(:course, :upcoming, title: 'A published future course')
  end

  it 'includes all courses allowed to be displayed in the course list' do
    expect(scope).to contain_exactly(
      # Please note: Also the course in preparation is allowed to be displayed.
      # If courses in preparation shall not be shown, the courses additionally
      # need to be filtered by state.
      an_object_having_attributes(title: 'An upcoming course in preparation'),
      an_object_having_attributes(title: 'An active and current course'),
      an_object_having_attributes(title: 'A hidden course'),
      an_object_having_attributes(title: 'A group-restricted course'),
      an_object_having_attributes(title: 'An archived course'),
      an_object_having_attributes(title: 'A published future course')
    )
  end
end
