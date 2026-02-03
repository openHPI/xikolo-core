# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Course List', type: :request do
  subject(:show_dashboard) { get '/dashboard', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }

  before do
    stub_user_request(id: user_id)

    # Stubs for the sidebar content
    Stub.request(
      :course, :get, '/enrollments',
      query: hash_including(user_id:, learning_evaluation: 'true')
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/courses',
      query: {promoted_for: user_id}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: {user_id:}
    ).to_return Stub.json([])
    Stub.request(
      :account, :post, '/tokens',
      body: hash_including(user_id:)
    ).to_return Stub.json({token: 'abc'})
  end

  it 'shows the user dashboard' do
    show_dashboard
    expect(response).to be_successful
  end

  it 'always shows the hint linking to the course page' do
    show_dashboard
    expect(response.body).to include 'Hint: You can still find all other courses you are not yet enrolled for'
  end

  it 'always shows the empty state for the upcoming courses category' do
    show_dashboard
    expect(response.body).not_to include 'My current courses'
    expect(response.body).to include 'My upcoming courses'
    expect(response.body).to include 'You are not enrolled in any upcoming courses.'
    expect(response.body).not_to include 'My completed courses'
  end

  context 'with current courses' do
    before do
      course1 = create(:course, :preparing,
        title: 'A non-published course that would run now',
        start_date: 5.days.ago,
        end_date: 1.month.from_now)
      create(:enrollment, user_id:, course: course1)

      course2 = create(:course, :active,
        title: 'An active and current course')
      create(:enrollment, user_id:, course: course2)

      course3 = create(:course, :active,
        title: 'An active course not shown on the course list',
        show_on_list: false)
      create(:enrollment, user_id:, course: course3)

      course4 = create(:course, :active, :hidden,
        title: 'An active and current but hidden course')
      create(:enrollment, user_id:, course: course4)

      course5 = create(:course, :active, :deleted,
        title: 'An active and current but deleted course')
      create(:enrollment, user_id:, course: course5)

      course6 = create(:course, :active, :deleted,
        title: 'An active and current course with deleted enrollment')
      create(:enrollment, user_id:, course: course6, deleted: true)

      course7 = create(:course, :archived,
        title: 'An archived course')
      create(:enrollment, user_id:, course: course7)

      create(:course, :active, title: 'An active and current course (not enrolled)')
    end

    it 'shows non-deleted, current (active or archived) courses the user is enrolled in, including hidden courses' do
      show_dashboard
      expect(response.body).to include 'My current courses'
      expect(response.body).to include 'My upcoming courses'
      expect(response.body).to include 'You are not enrolled in any upcoming courses.'
      expect(response.body).not_to include 'My completed courses'

      expect(response.body).to include 'An active and current course'
      expect(response.body).to include 'An active course not shown on the course list'
      expect(response.body).to include 'An active and current but hidden course'
      expect(response.body).to include 'An archived course'
      expect(response.body).not_to include 'A non-published course that would run now'
      expect(response.body).not_to include 'An active and current but deleted course'
      expect(response.body).not_to include 'An active and current course with deleted enrollment'
      expect(response.body).not_to include 'An active and current course (not enrolled)'

      page = Capybara.string(response.body)
      expect(page).to have_link 'Show details', count: 4
      expect(page).to have_link 'Mark as completed', count: 4
    end
  end

  context 'with upcoming courses' do
    before do
      course1 = create(:course, :preparing,
        title: 'A non-published and upcoming course')
      create(:enrollment, user_id:, course: course1)

      course2 = create(:course, :upcoming,
        title: 'An upcoming course')
      create(:enrollment, user_id:, course: course2)

      course3 = create(:course, :upcoming,
        title: 'An upcoming course not shown on the course list',
        show_on_list: false)
      create(:enrollment, user_id:, course: course3)

      course4 = create(:course, :upcoming, :hidden,
        title: 'An upcoming but hidden course')
      create(:enrollment, user_id:, course: course4)

      course5 = create(:course, :upcoming, :deleted,
        title: 'An upcoming but deleted course')
      create(:enrollment, user_id:, course: course5)

      course6 = create(:course, :upcoming,
        title: 'An upcoming course with deleted enrollment')
      create(:enrollment, user_id:, course: course6, deleted: true)

      create(:course, :upcoming, title: 'An upcoming course (not enrolled)')
    end

    it 'shows non-deleted, upcoming courses the user is enrolled in, including hidden courses' do
      show_dashboard
      expect(response.body).to include 'My upcoming courses'
      expect(response.body).not_to include 'You are not enrolled in any upcoming courses.'
      expect(response.body).not_to include 'My current courses'
      expect(response.body).not_to include 'My completed courses'

      expect(response.body).to include 'An upcoming course'
      expect(response.body).to include 'An upcoming course not shown on the course list'
      expect(response.body).to include 'An upcoming but hidden course'
      expect(response.body).not_to include 'A non-published and upcoming course'
      expect(response.body).not_to include 'An upcoming but deleted course'
      expect(response.body).not_to include 'An upcoming course with deleted enrollment'
      expect(response.body).not_to include 'An upcoming course (not enrolled)'

      expect(response.body).not_to include 'Mark as completed'
    end
  end

  context 'with courses marked as completed' do
    before do
      course1 = create(:course, :preparing,
        title: 'A non-published course that would run now',
        start_date: 5.days.ago,
        end_date: 1.month.from_now)
      create(:enrollment, user_id:, course: course1, completed: true)

      course2 = create(:course, :preparing,
        title: 'A non-published and upcoming course',
        start_date: 5.months.from_now,
        end_date: 6.months.from_now)
      create(:enrollment, user_id:, course: course2, completed: true)

      course3 = create(:course, :active,
        title: 'An active and current course')
      create(:enrollment, user_id:, course: course3, completed: true)

      course4 = create(:course, :active,
        title: 'An active course not shown on the course list',
        show_on_list: false)
      create(:enrollment, user_id:, course: course4, completed: true)

      course5 = create(:course, :active, :hidden,
        title: 'An active and current but hidden course')
      create(:enrollment, user_id:, course: course5, completed: true)

      course6 = create(:course, :active, :deleted,
        title: 'An active and current but deleted course')
      create(:enrollment, user_id:, course: course6, completed: true)

      course7 = create(:course, :active, :deleted,
        title: 'An active and current course with deleted enrollment')
      create(:enrollment, user_id:, course: course7, deleted: true, completed: true)

      course8 = create(:course, :archived,
        title: 'An archived course')
      create(:enrollment, user_id:, course: course8, completed: true)

      course9 = create(:course, :upcoming,
        title: 'An upcoming course')
      create(:enrollment, user_id:, course: course9, completed: true)

      course10 = create(:course, :upcoming,
        title: 'An upcoming course not shown on the course list',
        show_on_list: false)
      create(:enrollment, user_id:, course: course10, completed: true)

      course11 = create(:course, :upcoming, :hidden,
        title: 'An upcoming but hidden course')
      create(:enrollment, user_id:, course: course11, completed: true)

      course12 = create(:course, :upcoming, :deleted,
        title: 'An upcoming but deleted course')
      create(:enrollment, user_id:, course: course12, completed: true)

      course13 = create(:course, :upcoming,
        title: 'An upcoming course with deleted enrollment')
      create(:enrollment, user_id:, course: course13, deleted: true, completed: true)

      create(:course, :active, title: 'An active and current course (not enrolled)')
      create(:course, :upcoming, title: 'An upcoming course (not enrolled)')
    end

    it 'shows any non-deleted course the user is enrolled in and marked as completed' do
      show_dashboard
      expect(response.body).to include 'My completed courses'
      expect(response.body).to include 'My upcoming courses'
      expect(response.body).to include 'You are not enrolled in any upcoming courses.'
      expect(response.body).not_to include 'My current courses'

      expect(response.body).to include 'An active and current course'
      expect(response.body).to include 'An active course not shown on the course list'
      expect(response.body).to include 'An active and current but hidden course'
      expect(response.body).to include 'An archived course'
      expect(response.body).not_to include 'A non-published course that would run now'
      expect(response.body).not_to include 'A non-published and upcoming course'
      expect(response.body).not_to include 'An active and current but deleted course'
      expect(response.body).not_to include 'An active and current course with deleted enrollment'
      expect(response.body).not_to include 'An active and current course (not enrolled)'

      expect(response.body).to include 'An upcoming course'
      expect(response.body).to include 'An upcoming course not shown on the course list'
      expect(response.body).to include 'An upcoming but hidden course'
      expect(response.body).not_to include 'An upcoming but deleted course'
      expect(response.body).not_to include 'An upcoming course with deleted enrollment'
      expect(response.body).not_to include 'An upcoming course (not enrolled)'

      expect(response.body).not_to include 'Mark as completed'
    end
  end

  context 'as anonymous user' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      show_dashboard
      expect(request).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
