# frozen_string_literal: true

require 'spec_helper'

describe Navigation::CoursesMenu, type: :component do
  subject(:component) { described_class.new user: }

  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'features' => {'course_list' => true},
      'user' => {'anonymous' => true}
    )
  end

  it 'links to the courses page' do
    render_inline(component)
    expect(page).to have_link 'Courses', href: '/courses'
  end

  describe 'courses menu' do
    context 'with courses in all categories' do
      before do
        create(:course, :preparing, title: 'An upcoming course in preparation')
        create(:course, :active, title: 'An active and current course')
        create(:course, :active, title: 'An active and current course in a channel', channels: [create(:channel)])
        create(:course, :active, title: 'An active and current but not listed course', show_on_list: false)
        create(:course, :active, :hidden, title: 'A hidden course')
        create(:course, :active, :deleted, title: 'A deleted course')
        create(:course, :active, title: 'A group-restricted course', groups: %w[group.1])
        create(:course, :archived, title: 'An archived course')
        create(:course, :archived, title: 'An archived but not listed courses', show_on_list: false)
        create(:course, :upcoming, title: 'A published future course')
      end

      it 'lists all publicly available courses for the categories' do
        render_inline(component)

        expect(page).to have_link 'Courses', href: '/courses'

        expect(page).to have_content 'Current courses'
        expect(page).to have_content 'Upcoming courses'
        expect(page).to have_content 'Self-paced courses'
        expect(page).to have_link 'View all courses', count: 3

        expect(page).to have_no_link 'An upcoming course in preparation'
        expect(page).to have_no_link 'An active and current but not listed course'
        expect(page).to have_no_link 'A hidden course'
        expect(page).to have_no_link 'A deleted course'
        expect(page).to have_no_link 'A group-restricted course'
        expect(page).to have_no_link 'An archived but not listed courses'
        expect(page).to have_link 'An active and current course'
        expect(page).to have_link 'An active and current course in a channel'
        expect(page).to have_link 'An archived course'
        expect(page).to have_link 'A published future course'
      end
    end

    context 'with one courses category only' do
      before do
        create(:course, :archived, title: 'An archived course')
      end

      it 'lists only the courses for this category' do
        render_inline(component)

        expect(page).to have_link 'Courses', href: '/courses'

        expect(page).to have_no_content 'Current courses'
        expect(page).to have_no_content 'Upcoming courses'
        expect(page).to have_content 'Self-paced courses'
        expect(page).to have_link 'View all courses', count: 1

        expect(page).to have_link 'An archived course'
      end
    end
  end

  describe 'course order (in menu)' do
    subject(:courses) { component.send(:courses) }

    describe 'upcoming courses' do
      before do
        tomorrow = Date.tomorrow

        create(:course,
          title: 'A published far future course',
          status: 'active',
          start_date: 1.month.from_now,
          end_date: 2.months.from_now)
        create(:course,
          title: 'A published future course with display date',
          status: 'active',
          display_start_date: 2.days.from_now,
          start_date: 1.month.from_now,
          end_date: 2.months.from_now)
        create(:course,
          title: 'A published future course with different title',
          status: 'active',
          start_date: tomorrow,
          end_date: 1.month.from_now)
        create(:course,
          title: 'A published future course',
          status: 'active',
          start_date: tomorrow,
          end_date: 1.month.from_now)
      end

      it 'lists the upcoming courses by start date' do
        expect(courses[:upcoming]).to match [
          hash_including('title' => 'A published future course'),
          hash_including('title' => 'A published future course with different title'),
          hash_including('title' => 'A published future course with display date'),
          hash_including('title' => 'A published far future course'),
        ]
      end
    end
  end
end
