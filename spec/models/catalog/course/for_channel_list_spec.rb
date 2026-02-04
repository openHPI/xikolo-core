# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.for_channel_list', type: :model do
  subject(:scope) { described_class.for_channel_list(channel) }

  let(:channel) { create(:channel) }

  before do
    create(:course, :preparing, title: 'An upcoming course in preparation').channels << channel
    create(:course, :active, title: 'An active and current course').channels << channel
    create(:course, :active, title: 'An active and current course in another channel').channels << create(:channel)
    create(:course, :active, title: 'An active and current but not listed course', show_on_list: false).channels << channel
    create(:course, :active, :hidden, title: 'A hidden course').channels << channel
    create(:course, :active, :deleted, title: 'A deleted course').channels << channel
    create(:course, :active, title: 'A group-restricted course', groups: %w[group.1]).channels << channel
    create(:course, :archived, title: 'An archived course').channels << channel
    create(:course, :archived, title: 'An archived but not listed courses', show_on_list: false).channels << channel
    create(:course, :upcoming, title: 'A published future course').channels << channel
  end

  it 'includes all courses allowed to be displayed in the course list' do
    expected_titles = [
      'An upcoming course in preparation',
      'An active and current course',
      'An active and current but not listed course',
      'A hidden course',
      'A group-restricted course',
      'An archived course',
      'An archived but not listed courses',
      'A published future course',
    ]

    actual_titles = Catalog::Course.for_channel_list(channel).pluck(:title)
    expect(actual_titles).to match_array(expected_titles)
  end
end
