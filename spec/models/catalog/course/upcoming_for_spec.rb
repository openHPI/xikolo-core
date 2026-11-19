# frozen_string_literal: true

require 'spec_helper'

describe Catalog::Course, '.upcoming_for', type: :model do
  subject(:scope) { described_class.upcoming_for(user, enrollments) }

  let(:enrollments) { [] }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:user_id) { session.user.id }

  before do
    course1 = create(:course,
      title: 'A non-published course that would run now',
      published: false,
      start_date: 5.days.ago,
      end_date: 1.month.from_now)
    enrollments << create(:enrollment, course: course1, user_id:)

    course2 = create(:course,
      title: 'A non-published course without dates',
      published: false,
      start_date: nil,
      end_date: nil)
    enrollments << create(:enrollment, course: course2, user_id:)

    course3 = create(:course,
      title: 'An upcoming course in preparation',
      published: false,
      start_date: 5.months.from_now,
      end_date: 6.months.from_now)
    enrollments << create(:enrollment, course: course3, user_id:)

    course4 = create(:course,
      title: 'A published future course',
      start_date: Date.tomorrow,
      end_date: nil)
    enrollments << create(:enrollment, course: course4, user_id:)

    course5 = create(:course,
      title: 'A never ending course with start date',
      start_date: Date.yesterday,
      end_date: nil)
    enrollments << create(:enrollment, course: course5, user_id:)

    course6 = create(:course,
      title: 'A never ending course without start date',
      start_date: nil,
      end_date: nil)
    enrollments << create(:enrollment, course: course6, user_id:)

    course7 = create(:course,
      title: 'An archived course',
      start_date: 1.month.ago,
      end_date: 5.days.ago)
    enrollments << create(:enrollment, course: course7, user_id:)

    course8 = create(:course,
      title: 'An active course with past end date',
      start_date: 1.month.ago,
      end_date: 1.day.ago)
    enrollments << create(:enrollment, course: course8, user_id:)

    course9 = create(:course,
      title: 'An active and current course',
      start_date: 5.days.ago,
      end_date: 1.month.from_now)
    enrollments << create(:enrollment, course: course9, user_id:)

    course10 = create(:course,
      title: 'A published future course (completed)',
      start_date: Date.tomorrow,
      end_date: nil)
    enrollments << create(:enrollment, course: course10, user_id:, completed: true)

    create(:course,
      title: 'A published future course (not enrolled)',
      start_date: Date.tomorrow,
      end_date: nil)

    # The following stubs are needed to remove already completed courses.
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(user_id:, learning_evaluation: 'true')
    ).to_return Stub.json([
      build(:'course:enrollment:evaluated', user_id:, course_id: course10.id),
    ])
  end

  it 'returns courses with a start date in the future the user is enrolled in' do
    expect(scope).to contain_exactly(
      have_attributes(title: 'A published future course')
    )
  end

  describe 'sorting' do
    let(:enrollments) { [] }

    before do
      one_year_from_now = 1.year.from_now

      course1 = create(:course,
        title: 'Upcoming next year, but with another title',
        start_date: one_year_from_now,
        end_date: 1.year.from_now + 1.month)
      enrollments << create(:enrollment, course: course1, user_id:)

      course2 = create(:course,
        title: 'Upcoming next year',
        start_date: one_year_from_now,
        end_date: 1.year.from_now + 1.month)
      enrollments << create(:enrollment, course: course2, user_id:)

      course3 = create(:course,
        title: 'Upcoming next month',
        start_date: 1.month.from_now,
        end_date: 2.months.from_now)
      enrollments << create(:enrollment, course: course3, user_id:)

      course4 = create(:course,
        title: 'Upcoming later next week, but shown as later this week',
        start_date: 10.days.from_now,
        display_start_date: 3.days.from_now,
        end_date: 1.month.from_now)
      enrollments << create(:enrollment, course: course4, user_id:)

      course5 = create(:course,
        title: 'Upcoming next week',
        start_date: 1.week.from_now,
        end_date: 1.month.from_now)
      enrollments << create(:enrollment, course: course5, user_id:)

      course6 = create(:course,
        title: 'Upcoming day after tomorrow',
        start_date: 2.days.from_now,
        end_date: 1.month.from_now)
      enrollments << create(:enrollment, course: course6, user_id:)
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
