# frozen_string_literal: true

require 'spec_helper'

describe 'Item: Section Navigation', type: :system do
  let(:user_id) { generate(:user_id) }
  let(:user) { build(:'account:user', id: user_id, permissions:) }
  let(:permissions) { %w[course.content.access.available course.content.access] }
  let(:course) { create(:course, course_params) }
  let(:course_resource) { build(:'course:course', **course_params, id: course.id) }
  let(:richtext) { create(:richtext, id: item['content_id'], course:) }
  let(:course_params) { {} }
  let(:section) do
    build(:'course:section', course_id: course.id, title: 'Week 1')
  end
  let(:item) do
    build(:'course:item',
      title: 'Regular course item',
      content_type: 'rich_text',
      course_id: course.id,
      section_id: section['id'],
      content_id: generate(:uuid),
      show_in_nav: true)
  end
  let(:open_mode_item) do
    build(:'course:item', :video,
      title: 'Open mode item',
      course_id: course.id,
      section_id: section['id'],
      content_id: video.id,
      show_in_nav: true,
      open_mode: true)
  end
  let(:video) { create(:video) }

  def switch_to_mobile_view
    page.current_window.resize_to('768', '1024')
  end

  def visit_item_page(item_id)
    visit "/courses/#{course.course_code}/sections/#{section['id']}/items/#{item_id}"
  end

  before do
    richtext
    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json({id: user_id})
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .and_return Stub.json({properties: {}})

    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)

    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: course.id, user_id:}
    ).to_return Stub.json([{}])

    Stub.request(
      :course, :get, '/items',
      query: hash_including(section_id: section['id'])
    ).to_return Stub.json([item, open_mode_item])
    Stub.request(
      :course, :get, "/items/#{item['id']}"
    ).to_return Stub.json(item)
    Stub.request(
      :course, :get, "/items/#{open_mode_item['id']}",
      query: hash_including({})
    ).to_return Stub.json(open_mode_item)
    Stub.request(:course, :get, "/sections/#{section['id']}")
      .to_return Stub.json(section)
    Stub.request(
      :course, :get, '/sections',
      query: {course_id: course.id}
    ).to_return Stub.json([section])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
    Stub.request(
      :course, :post, "/items/#{item['id']}/users/#{user_id}/visit",
      body: hash_including({})
    ).to_return Stub.response(status: 201)
    Stub.request(
      :course, :post, "/items/#{open_mode_item['id']}/users/#{user_id}/visit",
      body: hash_including({})
    ).to_return Stub.response(status: 201)

    Stub.service(:pinboard, build(:'pinboard:root'))
    Stub.request(:pinboard, :get, '/topics', query: {item_id: open_mode_item['id']})
      .to_return Stub.json([])
  end

  context 'as an anonymous user' do
    describe 'visiting a course item in open mode' do
      let(:user_id) { 'anonymous' }

      it 'shows only open mode items' do
        visit_item_page(open_mode_item['id'])

        expect(page.find_by_id('sectionnav')).to have_no_link('Regular course item')
        expect(page.find_by_id('sectionnav')).to have_link('Open mode item')
      end
    end
  end

  context 'as a logged in user' do
    before do
      stub_user(id: user_id, permissions:)
    end

    describe 'visiting a course item in open mode' do
      context 'with course content permission' do
        it 'shows all items as visitable' do
          visit_item_page(open_mode_item['id'])

          expect(page.find_by_id('sectionnav')).to have_link('Regular course item')
          expect(page.find_by_id('sectionnav')).to have_link('Open mode item')
        end
      end

      context 'without course content permission' do
        let(:permissions) { [] }

        it 'shows items that are not visitable in open mode as locked' do
          visit_item_page(open_mode_item['id'])

          expect(page.find_by_id('sectionnav')).to have_no_link('Regular course item')
          expect(page.find_by_id('sectionnav')).to have_text('Open mode item')
        end
      end
    end

    describe 'toggle via button' do
      it 'expands and collapses the section navigation on the side' do
        visit_item_page(item['id'])
        # Check for section navigation on the side and a navigation item
        expect(page.find_by_id('togglenav_horizontal')).to have_content 'Hide navigation'
        expect(page).to have_content 'Week 1'

        # Click to collapse the section navigation on the side
        find_by_id('togglenav_horizontal').click

        # Collapsed section navigation on the side
        expect(page.find('.course-navbar-toggle')).to be_truthy
        expect(page).to have_no_content 'Week 1'

        # Click to expand the section navigation on the side
        find('.course-navbar-toggle').click

        # Check for section navigation on the side and a navigation item
        expect(page.find_by_id('togglenav_horizontal')).to have_content 'Hide navigation'
        expect(page).to have_content 'Week 1'
      end

      context 'in mobile view' do
        before do
          switch_to_mobile_view
        end

        it 'expands and collapses the section navigation on the bottom' do
          visit_item_page(item['id'])
          # Check for section navigation and a navigation item
          expect(page.find_by_id('togglenav_vertical')).to have_content 'Hide navigation'
          expect(page).to have_content 'Week 1'

          # Click to collapse the section navigation
          find_by_id('togglenav_vertical').click

          # Check for collapsed section navigation
          expect(page.find_by_id('togglenav_vertical')).to have_content 'Show navigation'
          expect(page).to have_no_content 'Week 1'

          # Click to expand the section navigation
          find_by_id('togglenav_vertical').click

          # Check for section navigation and a navigation item
          expect(page.find_by_id('togglenav_vertical')).to have_content 'Hide navigation'
          expect(page).to have_content 'Week 1'
        end
      end
    end

    describe 'default behavior based on user setting' do
      describe 'to show the navigation' do
        before do
          page.execute_script "window.localStorage.setItem('section_navigation_expanded','true');"
        end

        it 'displays the section navigation on the side' do
          visit_item_page(item['id'])
          expect(page.find_by_id('togglenav_horizontal')).to have_content 'Hide navigation'
          expect(page).to have_content 'Week 1'
        end

        context 'in mobile view' do
          before do
            switch_to_mobile_view
          end

          it 'displays a section navigation on the bottom' do
            visit_item_page(item['id'])
            expect(page.find_by_id('togglenav_vertical')).to have_content 'Hide navigation'
            expect(page).to have_content 'Week 1'
          end
        end
      end

      describe 'to hide the navigation' do
        before do
          page.execute_script "window.localStorage.setItem('section_navigation_expanded','false');"
        end

        it 'displays a collapsed section navigation on the side' do
          visit_item_page(item['id'])
          expect(page.find('.course-navbar-toggle')).to be_truthy
          expect(page).to have_no_content 'Week 1'
        end

        context 'in mobile view' do
          before do
            switch_to_mobile_view
          end

          it 'displays a collapsed section navigation on the bottom' do
            visit_item_page(item['id'])
            expect(page.find_by_id('togglenav_vertical')).to have_content 'Show navigation'
            expect(page).to have_no_content 'Week 1'
          end
        end
      end
    end

    describe '(pinboard link)' do
      it 'has a discussions link by default' do
        visit_item_page(item['id'])
        expect(page.find_by_id('leftnav')).to have_content 'Discussions'
      end

      context 'with disabled pinboard' do
        let(:course_params) { super().merge(pinboard_enabled: false) }

        it 'has no discussions link' do
          visit_item_page(item['id'])
          expect(page.find_by_id('leftnav')).to have_content 'Week 1'
          expect(page.find_by_id('leftnav')).to have_no_content 'Discussions'
        end
      end
    end
  end
end
