# frozen_string_literal: true

require 'spec_helper'

describe Navigation::CoursesMenu, type: :component do
  subject(:component) { described_class.new user: }

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

  it 'links to the courses page' do
    render_inline(component)
    expect(page).to have_link 'Learn', href: '/learn'
  end

  describe 'courses menu' do
    context 'with courses in all categories' do
      before do
        create(:course, :preparing, title: 'An upcoming course in preparation')
        create(:course, :active, title: 'An active and current course')
        create(:course, :active, title: 'An active and current course in a channel', channels: [create(:'course_service/channel')])
        create(:course, :active, title: 'An active and current but not listed course', placement: [])
        create(:course, :active, :hidden, title: 'A hidden course')
        create(:course, :active, :deleted, title: 'A deleted course')
        create(:course, :active, title: 'A group-restricted course', groups: %w[group.1])
        create(:course, :self_paced, title: 'An self-paced course')
        create(:course, :self_paced, title: 'An self-paced but not listed courses', placement: [])
        create(:course, :upcoming, title: 'A published future course')
      end

      it 'lists all publicly available courses for the categories' do
        render_inline(component)

        expect(page).to have_link 'Learn', href: '/learn'

        expect(page).to have_text 'Happening now'
        expect(page).to have_text 'Coming soon'
        expect(page).to have_text 'Go at your own pace'
        expect(page).to have_link 'View all courses', count: 3

        expect(page).to have_no_link 'An upcoming course in preparation'
        expect(page).to have_no_link 'An active and current but not listed course'
        expect(page).to have_no_link 'A hidden course'
        expect(page).to have_no_link 'A deleted course'
        expect(page).to have_no_link 'A group-restricted course'
        expect(page).to have_no_link 'An self-paced but not listed courses'
        expect(page).to have_link 'An active and current course'
        expect(page).to have_link 'An active and current course in a channel'
        expect(page).to have_link 'An self-paced course'
        expect(page).to have_link 'A published future course'
      end
    end

    context 'with one courses category only' do
      before do
        create(:course, :self_paced, title: 'An self-paced course')
      end

      it 'lists only the courses for this category' do
        render_inline(component)

        expect(page).to have_link 'Learn', href: '/learn'

        expect(page).to have_no_text 'Happening now'
        expect(page).to have_no_text 'Coming soon'
        expect(page).to have_text 'Go at your own pace'
        expect(page).to have_link 'View all courses', count: 1

        expect(page).to have_link 'An self-paced course'
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
          start_date: 1.month.from_now,
          end_date: 2.months.from_now)
        create(:course,
          title: 'A published future course with display date',
          display_start_date: 2.days.from_now,
          start_date: 1.month.from_now,
          end_date: 2.months.from_now)
        create(:course,
          title: 'A published future course with different title',
          start_date: tomorrow,
          end_date: 1.month.from_now)
        create(:course,
          title: 'A published future course',
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
