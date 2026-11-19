# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Pinboard: List', type: :request do
  subject(:list_threads) do
    get "/learn/#{course.id}/pinboard", params:
  end

  let(:params) { {} }
  let(:course) { create(:'course_service/course', :active) }
  let(:page) { Capybara::Node::Simple.new(response.body) }

  context 'as an anonymous user' do
    it 'redirects to the login page' do
      list_threads
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'as a logged-in user' do
    let(:user) { create(:'account_service/user') }

    before { sign_in(user:) }

    context 'not enrolled in the course' do
      it 'redirects to the course page' do
        list_threads
        expect(response).to redirect_to course_url(course.course_code)
      end
    end

    context 'enrolled in the course' do
      before do
        role = create(:'account_service/role', permissions: %w[course.content.access])
        create(:'account_service/grant', principal: user, role:)
        create(:enrollment, course_id: course.id, user_id: user.id)
      end

      context 'without questions' do
        it 'shows an empty state' do
          list_threads

          expect(page).to have_text 'Sorry, nothing here yet.'
        end
      end

      context 'with questions' do
        before do
          create(:'pinboard_service/question', title: 'Question 1', course_id: course.id, updated_at: 2.hours.ago)
          create(:'pinboard_service/question_with_vote', title: 'Question 2', course_id: course.id, updated_at: 1.day.ago)
          create(:'pinboard_service/question', title: 'Question 3', course_id: course.id, updated_at: 2.days.ago)
        end

        it 'lists all topics' do
          list_threads

          first_row = page.find('tr:nth(1)')
          second_row = page.find('tr:nth(2)')
          third_row = page.find('tr:nth(3)')

          expect(first_row).to have_text('Question 1')
            .and have_text('about 2 hours ago')
          expect(second_row).to have_text('Question 2')
            .and have_text('1 vote')
          expect(third_row).to have_text('Question 3')
        end
      end

      it 'has a filter bar' do
        list_threads

        page.find('form[action*=pinboard]').tap do |filter_bar|
          expect(filter_bar).to have_select('Sort by', options: ['Most recent activity', 'Latest questions', 'Best voted first'])
          expect(filter_bar).to have_field('Search')
          expect(filter_bar).to have_no_select('Tags')
        end
      end

      context 'with explicit tags available' do
        before do
          Stub.request(:pinboard, :get, '/explicit_tags',
            query: hash_including(course_id: course.id))
            .to_return Stub.json([{id: generate(:uuid), name: 'Databases', course_id: course.id}])
        end

        it 'has a tags select in the filter bar' do
          list_threads

          page.find('form[action*=pinboard]').tap do |filter_bar|
            # The placeholder is part of the options for a multiple select
            expect(filter_bar).to have_select('Tags', options: ['Select tags', 'Databases'])
          end
        end
      end

      it 'has a select to show topics in different sections' do
        list_threads

        expect(page).to have_select('Show topics in', options: ['All discussions', 'Technical Issues'])
      end

      context 'with technical issues disabled' do
        before do
          xi_config <<~YML
            disable_technical_issues_section: true
          YML
        end

        it 'does not show a section select' do
          list_threads

          expect(page).to have_no_select('Show topics in')
        end
      end

      context 'with a course section available' do
        before do
          xi_config <<~YML
            disable_technical_issues_section: false
          YML
          create(:'course_service/section', course:, title: 'Week 1')
        end

        it 'shows a section select with the course section as option' do
          list_threads

          expect(page).to have_select('Show topics in', options: ['All discussions', 'Technical Issues', 'Week 1'])
        end
      end
    end
  end
end
