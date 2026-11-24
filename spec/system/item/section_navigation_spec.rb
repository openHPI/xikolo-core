# frozen_string_literal: true

require 'spec_helper'

describe 'Item: Section Navigation', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:video) { create(:video) }
  let(:richtext) { create(:'course_service/richtext', course:) }
  let!(:item) do
    create(
      :'course_service/item',
      section:,
      title: 'Regular course item',
      content: richtext,
      open_mode: false
    )
  end
  let!(:open_mode_item) do
    create(
      :'course_service/item',
      section:,
      title: 'Open mode item',
      content: video,
      open_mode: true
    )
  end

  def visit_item_page(item_id)
    visit "/learn/#{course.course_code}/items/#{item_id}"
  end

  def open_section_nav_drawer
    find('.x-drawer-button').click
    expect(section_navigation(visible: true)).to have_text 'Week 1'
  end

  def section_navigation(visible: true, wait: Capybara.default_max_wait_time)
    page.find(
      ".x-drawer-side > div[aria-label='Toggle navigation']",
      visible:,
      wait:
    )
  end

  context 'as an anonymous user' do
    describe 'visiting a course item in open mode' do
      it 'shows only open mode items' do
        visit_item_page(open_mode_item['id'])

        open_section_nav_drawer

        expect(section_navigation).to have_no_link('Regular course item')
        expect(section_navigation).to have_link('Open mode item')
      end

      it 'shows no course progress' do
        visit_item_page(open_mode_item['id'])

        open_section_nav_drawer

        expect(section_navigation).to have_no_css('progress')
      end
    end
  end

  context 'as a logged in user' do
    let!(:user) { sign_in }

    describe 'bottom item navigation' do
      before { enroll_in(course) }

      it 'follows the next and previous links within the section' do
        visit_item_page(item.id)

        within('nav[aria-label="Course actions"]') do
          expect(page).to have_link('Next', href: "/learn/#{course.id}/items/#{open_mode_item.id}#course-item-header")
          click_on 'Next'
        end

        expect(page).to have_current_path "/learn/#{course.id}/items/#{open_mode_item.id}"

        within('nav[aria-label="Course actions"]') do
          expect(page).to have_link('Previous', href: "/learn/#{course.id}/items/#{item.id}#course-item-header")
          click_on 'Previous'
        end

        expect(page).to have_current_path "/learn/#{course.id}/items/#{item.id}"
        expect(page).to have_text 'Regular course item'
      end
    end

    describe 'bottom navigation with preview permission' do
      let(:course) { create(:'course_service/course', :active, :with_content_tree) }
      let!(:user) do
        admin = create(:'account_service/user')
        role = create(:'account_service/role', permissions: ['course.content.access'])
        create(:'account_service/grant', principal: admin, role:)
        sign_in(user: admin)
      end

      before do
        enroll_in(course)
        fork = create(:'course_service/fork', section:, course:)
        item.node.move_to_child_of(fork.branches[0].node)
        open_mode_item.node.move_to_child_of(fork.branches[1].node)
        section.node.reload
        fork.content_test.group_for_user(user.id)
      end

      it 'follows positional neighbors across content-test branches' do
        visit_item_page(item.id)
        within('nav[aria-label="Course actions"]') { click_on 'Next' }
        expect(page).to have_current_path "/learn/#{course.id}/items/#{open_mode_item.id}"

        within('nav[aria-label="Course actions"]') { click_on 'Previous' }
        expect(page).to have_current_path "/learn/#{course.id}/items/#{item.id}"
      end
    end

    describe '(course progress)' do
      before do
        create(:'course_service/item', section:, title: 'Unvisited item')
        enroll_in(course)
        [item, open_mode_item].each { create(:'course_service/visit', item: it, user_id: user.id) }
      end

      it 'shows the overall course progress' do
        visit_item_page(item['id'])

        expect(page).to have_css('turbo-frame#course-progress:not([complete])', visible: :all)

        open_section_nav_drawer

        within(section_navigation) do
          expect(page).to have_text 'Progress'
          expect(page).to have_text '66%'
          expect(page).to have_css('progress[value="66"]')
        end
      end

      it 'marks the completed items' do
        visit_item_page(item['id'])

        open_section_nav_drawer

        within(section_navigation) do
          expect(page).to have_link('Regular course item') {|link| link.has_css?('.sr-only', exact_text: 'Completed', visible: :all) }
          expect(page).to have_link('Open mode item') {|link| link.has_css?('.sr-only', exact_text: 'Completed', visible: :all) }
          expect(page).to have_link('Unvisited item') {|link| link.has_no_css?('.sr-only', exact_text: 'Completed', visible: :all) }
        end
      end
    end

    describe 'navigation between sections' do
      let!(:next_section) { create(:'course_service/section', course:, title: 'Week 2') }
      let!(:next_item) do
        create(:'course_service/item', section: next_section, title: 'Week 2 introduction',
          content: richtext)
      end

      before { enroll_in(course) }

      it 'follows the next and previous section links' do
        visit_item_page(open_mode_item.id)
        click_link 'Next module'
        expect(page).to have_current_path("/learn/#{course.id}/items/#{next_item.id}")

        click_link 'Previous module'
        expect(page).to have_current_path("/learn/#{course.id}/items/#{open_mode_item.id}")
      end
    end

    describe 'visiting a course item in open mode' do
      context 'with course content permission' do
        before { enroll_in(course) }

        it 'shows all items as visitable' do
          visit_item_page(open_mode_item['id'])

          open_section_nav_drawer

          within(section_navigation(wait: 10)) do
            expect(page).to have_link('Regular course item')
            expect(page).to have_link('Open mode item')
          end
        end
      end

      context 'without course content permission' do
        it 'shows items that are not visitable in open mode as locked' do
          visit_item_page(open_mode_item['id'])

          open_section_nav_drawer

          expect(section_navigation).to have_no_link('Regular course item')
          expect(section_navigation).to have_text('Open mode item')
        end
      end
    end

    describe 'overview link' do
      before { enroll_in(course) }

      it 'links to the course overview above the sections' do
        visit_item_page(item['id'])

        open_section_nav_drawer

        expect(section_navigation).to have_link('Go to overview', href: "/learn/#{course.course_code}/overview")
      end
    end

    describe 'expanding a section' do
      let(:other_section) { create(:'course_service/section', course:, title: 'Week 2', position: 2) }

      before do
        enroll_in(course)
        create(:'course_service/item', :quiz, section: other_section, title: 'Other section item')
      end

      it 'shows the items of the section without leaving the current page' do
        visit_item_page(item['id'])

        open_section_nav_drawer

        within(section_navigation) do
          expect(page).to have_link('Regular course item')
          expect(page).to have_no_link('Other section item')

          find('summary', text: 'Week 2').click

          expect(page).to have_link('Other section item')
        end

        expect(page).to have_current_path "/learn/#{course.course_code}/items/#{item['id']}"
      end
    end
  end
end
