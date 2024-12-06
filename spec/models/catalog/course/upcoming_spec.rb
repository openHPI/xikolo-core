# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.upcoming', type: :model do
  subject(:scope) { described_class.upcoming }

  before do
    create(:course,
      title: 'A never-published course that would run now',
      status: 'preparation',
      start_date: 5.days.ago,
      end_date: 1.month.from_now)

    create(:course,
      title: 'An upcoming course in preparation',
      status: 'preparation',
      start_date: 5.months.from_now)

    create(:course,
      title: 'A published future course',
      status: 'active',
      start_date: Date.tomorrow,
      end_date: nil)

    create(:course,
      title: 'A never ending course with start date',
      status: 'active',
      start_date: Date.yesterday,
      end_date: nil)

    create(:course,
      title: 'A never ending course without start date',
      status: 'active',
      start_date: nil,
      end_date: nil)

    create(:course,
      title: 'An archived course',
      status: 'archive',
      start_date: 1.month.ago,
      end_date: 5.days.ago)

    create(:course,
      title: 'An active course with past end date',
      status: 'active',
      start_date: 1.month.ago,
      end_date: 1.day.ago)

    create(:course,
      title: 'An active and current course',
      status: 'active',
      start_date: 5.days.ago,
      end_date: 1.month.from_now)
  end

  it 'returns published courses with a start date in the future' do
    expect(scope).to contain_exactly(have_attributes(title: 'A published future course'))
  end

  describe 'sorting' do
    before do
      one_year_from_now = 1.year.from_now

      create(:course,
        status: 'active',
        title: 'Upcoming next year, but with another title',
        start_date: one_year_from_now)

      create(:course,
        status: 'active',
        title: 'Upcoming next year',
        start_date: one_year_from_now)

      create(:course,
        status: 'active',
        title: 'Upcoming next month',
        start_date: 1.month.from_now)

      create(:course,
        status: 'active',
        title: 'Upcoming later next week, but shown as later this week',
        start_date: 10.days.from_now,
        display_start_date: 3.days.from_now)

      create(:course,
        status: 'active',
        title: 'Upcoming next week',
        start_date: 1.week.from_now)

      create(:course,
        status: 'active',
        title: 'Upcoming day after tomorrow',
        start_date: 2.days.from_now)
    end

    it 'returns next courses first and prefers the display start date over the start date' do
      expect(scope).to match [
        have_attributes(title: 'A published future course'),
        have_attributes(title: 'Upcoming day after tomorrow'),
        have_attributes(title: 'Upcoming later next week, but shown as later this week'),
        have_attributes(title: 'Upcoming next week'),
        have_attributes(title: 'Upcoming next month'),
        have_attributes(title: 'Upcoming next year'),
        have_attributes(title: 'Upcoming next year, but with another title'),
      ]
    end
  end
end
