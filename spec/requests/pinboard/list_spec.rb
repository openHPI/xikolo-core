# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Pinboard: List', type: :request do
  subject(:list_threads) do
    get "/courses/#{course.course_code}/pinboard", headers:, params:
  end

  let(:headers) { {} }
  let(:params) { {} }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code, id: course.id) }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:sections) { [] }
  let(:threads) { [] }
  let(:question_params) { {} }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id, include_alternatives: true, published: true, available: true}
    ).to_return Stub.json(sections)
    Stub.request(:pinboard, :get, '/explicit_tags',
      query: hash_including(course_id: course.id))
      .to_return Stub.json([])
    Stub.request(:pinboard, :get, '/questions',
      query: hash_including(question_params)).to_return Stub.json(threads)
  end

  context 'as an anonymous user' do
    it 'redirects to the login page' do
      list_threads
      expect(response).to redirect_to 'http://www.example.com/sessions/new'
    end
  end

  context 'as a logged-in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request }

    context 'not enrolled in the course' do
      it 'redirects to the course page' do
        list_threads
        expect(response).to redirect_to course_url(course.course_code)
      end
    end

    context 'enrolled in the course' do
      let!(:user) { stub_user_request permissions: %w[course.content.access] }
      let(:question_params) { {course_id: course.id} }

      before do
        create(:enrollment, course_id: course.id, user_id: user[:id])
      end

      context 'without questions' do
        it 'shows an empty state' do
          list_threads

          expect(page).to have_text 'Sorry, nothing here yet.'
        end
      end

      context 'with questions' do
        let(:threads) do
          [
            build(:'pinboard:question', title: 'Question 1', course: course.id, updated_at: 2.hours.ago),
            build(:'pinboard:question', title: 'Question 2', course: course.id, votes: 1, updated_at: 1.day.ago),
            build(:'pinboard:question', title: 'Question 3', course: course.id, updated_at: 1.day.ago),
          ]
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
        end

        let(:sections) { [build(:'course:section', title: 'Week 1', course_id: course.id)] }

        it 'shows a section select with the course section as option' do
          list_threads

          expect(page).to have_select('Show topics in', options: ['All discussions', 'Technical Issues', 'Week 1'])
        end
      end
    end
  end
end
