# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.upcoming', type: :model do
  subject(:scope) { described_class.upcoming }

  before do
    create(:course,
      title: 'A never-published course that would run now',
      published: false,
      start_date: 5.days.ago,
      end_date: 1.month.from_now)

    create(:course,
      title: 'An upcoming course in preparation',
      published: false,
      start_date: 5.months.from_now,
      end_date: 6.months.from_now)

    create(:course,
      title: 'A published future course',
      start_date: Date.tomorrow,
      end_date: nil)

    create(:course,
      title: 'A never ending course with start date',
      start_date: Date.yesterday,
      end_date: nil)

    create(:course,
      title: 'A never ending course without start date',
      start_date: nil,
      end_date: nil)

    create(:course,
      title: 'An archived course',
      start_date: 1.month.ago,
      end_date: 5.days.ago)

    create(:course,
      title: 'An active course with past end date',
      start_date: 1.month.ago,
      end_date: 1.day.ago)

    create(:course,
      title: 'An active and current course',
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
        title: 'Upcoming next year, but with another title',
        start_date: one_year_from_now,
        end_date: 1.year.from_now + 1.month)

      create(:course,
        title: 'Upcoming next year',
        start_date: one_year_from_now,
        end_date: 1.year.from_now + 1.month)

      create(:course,
        title: 'Upcoming next month',
        start_date: 1.month.from_now,
        end_date: 2.months.from_now)

      create(:course,
        title: 'Upcoming later next week, but shown as later this week',
        start_date: 10.days.from_now,
        display_start_date: 3.days.from_now,
        end_date: 1.month.from_now)

      create(:course,
        title: 'Upcoming next week',
        start_date: 1.week.from_now,
        end_date: 1.month.from_now)

      create(:course,
        title: 'Upcoming day after tomorrow',
        start_date: 2.days.from_now,
        end_date: 1.month.from_now)
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
