# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.current', type: :model do
  subject(:scope) { described_class.current }

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

  it 'returns active, time-boxed courses during their runtime' do
    expect(scope).to contain_exactly(have_attributes(title: 'An active and current course'))
  end

  describe 'sorting' do
    before do
      one_week_ago = 1.week.ago

      create(:course,
        status: 'active',
        title: 'Started a week ago, but with another title',
        start_date: one_week_ago,
        end_date: 1.month.from_now)

      create(:course,
        status: 'active',
        title: 'Started a week ago',
        start_date: one_week_ago,
        end_date: 1.month.from_now)

      create(:course,
        status: 'active',
        title: 'Started a month ago',
        start_date: 1.month.ago,
        end_date: 1.month.from_now)

      create(:course,
        status: 'active',
        title: 'Started three months ago',
        start_date: 3.months.ago,
        end_date: 1.month.from_now)

      create(:course,
        status: 'active',
        title: 'Started four months ago, but shown as two months ago',
        start_date: 4.months.ago,
        display_start_date: 2.months.ago,
        end_date: 1.month.from_now)
    end

    it 'returns started long ago courses first and prefers the display start date over the start date' do
      expect(scope).to match [
        have_attributes(title: 'Started three months ago'),
        have_attributes(title: 'Started four months ago, but shown as two months ago'),
        have_attributes(title: 'Started a month ago'),
        have_attributes(title: 'Started a week ago'),
        have_attributes(title: 'Started a week ago, but with another title'),
        have_attributes(title: 'An active and current course'),
      ]
    end
  end
end
