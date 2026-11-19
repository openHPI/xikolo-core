# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Courses: Index', type: :request do
  describe 'published courses' do
    subject(:request) { get '/admin/learn' }

    let(:authenticate) { true }

    before do
      create(:'course_service/course', title: 'Course 1',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Course 2', published: true,
        start_date: 2.months.ago, end_date: 1.month.ago,
        skip_account_groups: true)
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists all courses' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Course 1'
          expect(page).to have_text 'active'
          expect(page).to have_text 'Course 2'
          expect(page).to have_text 'self-paced'
          expect(page).to have_css('.x-badge-success', text: 'active')
          expect(page).to have_css('.x-badge-neutral', text: 'self-paced')
        end
      end
    end
  end

  describe 'currently running courses (active filter)' do
    subject(:request) { get '/admin/learn?status=active' }

    before do
      create(:'course_service/course', title: 'Running Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Upcoming Course',
        start_date: 2.weeks.from_now, end_date: 8.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Hidden Running Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now, placement: [],
        skip_account_groups: true)
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists only currently running non-hidden courses' do
          request
          expect(response).to have_http_status :ok
          expect(page).to have_text 'Running Course'
          expect(page).to have_no_text 'Upcoming Course'
          expect(page).to have_no_text 'Hidden Running Course'
        end
      end
    end
  end

  describe 'hidden courses (hidden filter)' do
    subject(:request) { get '/admin/learn?status=hidden' }

    before do
      create(:'course_service/course', title: 'Hidden Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now, placement: [],
        skip_account_groups: true)
      create(:'course_service/course', title: 'Visible Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now,
        skip_account_groups: true)
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists only hidden courses' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Hidden Course'
          expect(page).to have_no_text 'Visible Course'
        end
      end
    end
  end

  describe 'upcoming courses' do
    subject(:request) { get '/admin/learn?status=upcoming' }

    before do
      create(:'course_service/course', title: 'Upcoming Course',
        start_date: 2.weeks.from_now, end_date: 8.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Running Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Preparation Course', published: false,
        start_date: 2.weeks.from_now, end_date: 8.weeks.from_now,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Hidden Upcoming Course',
        start_date: 2.weeks.from_now, end_date: 8.weeks.from_now, placement: [],
        skip_account_groups: true)
      create(:'course_service/course', title: 'No Start Date Course',
        start_date: nil, end_date: 8.weeks.from_now,
        skip_account_groups: true)
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists only upcoming courses' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Upcoming Course'
          expect(page).to have_no_text 'Hidden Upcoming Course'
          expect(page).to have_no_text 'Running Course'
          expect(page).to have_no_text 'Preparation Course'
          expect(page).to have_no_text 'No Start Date Course'
        end
      end
    end
  end

  describe 'self-paced courses' do
    subject(:request) { get '/admin/learn?status=self_paced' }

    before do
      create(:'course_service/course', title: 'Self-paced Course',
        start_date: 6.months.ago, end_date: 2.months.ago,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Auto-archived Course',
        start_date: 3.months.ago, end_date: 1.day.ago,
        skip_account_groups: true)
      create(:'course_service/course', title: 'Hidden Self-paced Course',
        start_date: 3.months.ago, end_date: 1.day.ago, placement: [],
        skip_account_groups: true)
      create(:'course_service/course', title: 'Currently Running Course',
        start_date: 2.weeks.ago, end_date: 4.weeks.from_now,
        skip_account_groups: true)
    end

    context 'as anonymous user' do
      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end
    end

    context 'as logged in user' do
      let(:user) { create(:'account_service/user') }

      before { sign_in(user:) }

      it 'redirects the user' do
        request
        expect(response).to have_http_status :see_other
      end

      context 'with permissions' do
        let(:user) { create(:'account_service/user', :admin) }
        let(:page) { Capybara.string(response.body) }

        it 'lists only non-hidden self-paced courses' do
          request
          expect(response).to have_http_status :ok

          expect(page).to have_text 'Self-paced Course'
          expect(page).to have_text 'Auto-archived Course'
          expect(page).to have_no_text 'Hidden Self-paced Course'
          expect(page).to have_no_text 'Currently Running Course'
        end
      end
    end
  end
end
