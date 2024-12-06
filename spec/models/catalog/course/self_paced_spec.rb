# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.self_paced', type: :model do
  subject(:scope) { described_class.self_paced }

  before do
    create(:course,
      title: 'A never-published course that would run now',
      status: 'preparation',
      start_date: 5.days.ago,
      end_date: 1.month.from_now)

    create(:course,
      title: 'A published future course',
      status: 'active',
      start_date: Date.tomorrow,
      end_date: nil)

    create(:course,
      title: 'A never ending course with start date',
      status: 'active',
      start_date: 2.days.ago,
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

  it 'returns endless and past courses' do
    expect(scope).to contain_exactly(have_attributes(title: 'A never ending course with start date'), have_attributes(title: 'A never ending course without start date'), have_attributes(title: 'An archived course'), have_attributes(title: 'An active course with past end date'))
  end

  describe 'sorting' do
    before do
      one_month_ago = 1.month.ago

      create(:course,
        title: 'Ended one month ago, but with another title',
        status: 'active',
        start_date: 2.months.ago,
        end_date: one_month_ago)

      create(:course,
        title: 'Ended one month ago',
        status: 'active',
        start_date: 2.months.ago,
        end_date: one_month_ago)

      create(:course,
        title: 'A never ending course with display start date',
        status: 'active',
        start_date: 1.day.ago,
        display_start_date: 3.days.ago,
        end_date: nil)
    end

    it 'returns recently ended courses first and prefers the end date over the display start date over the start date' do
      expect(scope).to match [
        have_attributes(title: 'An active course with past end date'), # ended one day ago
        have_attributes(title: 'A never ending course with start date'), # started two days ago
        have_attributes(title: 'A never ending course with display start date'), # displayed as started three days ago
        have_attributes(title: 'An archived course'), # ended five days ago
        have_attributes(title: 'Ended one month ago'),
        have_attributes(title: 'Ended one month ago, but with another title'),
        have_attributes(title: 'A never ending course without start date'),
      ]
    end
  end
end
