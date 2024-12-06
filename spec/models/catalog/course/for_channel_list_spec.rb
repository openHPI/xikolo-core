# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.for_channel_list', type: :model do
  subject(:scope) { described_class.for_channel_list(channel) }

  let(:channel) { create(:channel) }

  before do
    create(:course, :preparing, title: 'An upcoming course in preparation', channel:)
    create(:course, :active, title: 'An active and current course', channel:)
    create(:course, :active, title: 'An active and current course in another channel', channel: create(:channel))
    create(:course, :active, title: 'An active and current but not listed course', show_on_list: false, channel:)
    create(:course, :active, :hidden, title: 'A hidden course', channel:)
    create(:course, :active, :deleted, title: 'A deleted course', channel:)
    create(:course, :active, title: 'A group-restricted course', groups: %w[group.1], channel:)
    create(:course, :archived, title: 'An archived course', channel:)
    create(:course, :archived, title: 'An archived but not listed courses', show_on_list: false, channel:)
    create(:course, :upcoming, title: 'A published future course', channel:)
  end

  it 'includes all courses allowed to be displayed in the course list' do
    expect(scope).to contain_exactly(
      # Please note: Also the course in preparation is allowed to be displayed.
      # If courses in preparation shall not be shown, the courses additionally
      # need to be filtered by state.
      an_object_having_attributes(title: 'An upcoming course in preparation'),
      an_object_having_attributes(title: 'An active and current course'),
      an_object_having_attributes(title: 'An active and current but not listed course'),
      an_object_having_attributes(title: 'A hidden course'),
      an_object_having_attributes(title: 'A group-restricted course'),
      an_object_having_attributes(title: 'An archived course'),
      an_object_having_attributes(title: 'An archived but not listed courses'),
      an_object_having_attributes(title: 'A published future course')
    )
  end
end
