# frozen_string_literal: true

require 'spec_helper'
require 'webrick'

##
# A tiny web server that acts as a LTI app, accepts *any* POST request and returns a known response.
#
class LtiServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_POST(_, response) # rubocop:disable Naming/MethodName
    response.status = 200
    response.content_type = 'text/html'
    response.body = <<~HTML
      <html>
        <body>Welcome to LTI!</body>
      </html>
    HTML
  end
end

describe 'LTI: Tool Launch', gen: 2, type: :feature do
  around do |example|
    lti_server = WEBrick::HTTPServer.new Port: 11_000, Log: false, AccessLog: []
    lti_server.mount '/', LtiServlet
    Thread.new { lti_server.start }

    example.run

    lti_server.shutdown
  end

  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course, course_code: 'the_course') }
  let(:section) { create(:section, course:) }
  let(:item) { create(:item, section:, content: exercise) }
  let(:exercise) { create(:lti_exercise, provider:) }
  let(:provider) { create(:lti_provider) }
  let(:exercise_type) { 'main' }

  # These resources are needed for the Acfs/Restify-based items page
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code, context_id: course.context_id) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item_resource) do
    build(:'course:item', :lti_exercise,
      id: item.id,
      course_id: course.id,
      section_id: section.id,
      content_id: exercise.id,
      title: item.title,
      exercise_type:)
  end

  before do
    # We need two session stubs here, one for the actual course context the request is executed ...
    stub_user permissions: %w[course.content.access.available], id: user_id, context_id: course.context_id
    # ... and a second one in root context for a JS-triggered APIv2 call
    stub_user permissions: %w[course.content.access.available], id: user_id

    Stub.request(:account, :get, "/users/#{user_id}")
      .and_return Stub.json({id: user_id, email: 'kit@kat.com'})
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .and_return Stub.json({properties: {}})

    # Relevant stubs for the items page
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/courses/the_course')
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, "/courses/#{course.id}")
      .and_return Stub.json(course)
    Stub.request(:course, :get, '/api/v2/course/courses/the_course', query: hash_including({}))
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, '/enrollments', query: {user_id:, course_id: course.id})
      .and_return Stub.json([
        {course_id: course.id, user_id:},
      ])
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .and_return Stub.json([])
    Stub.request(:course, :get, '/sections', query: hash_including(course_id: course.id))
      .and_return Stub.json([])
    Stub.request(:course, :get, "/sections/#{section.id}")
      .and_return Stub.json(section_resource)
    Stub.request(:course, :get, '/items', query: hash_including(state_for: user_id))
      .and_return Stub.json([])
    Stub.request(:course, :get, "/items/#{item.id}", query: hash_including({}))
      .and_return Stub.json(item_resource)
    Stub.request(:course, :post, "/items/#{item.id}/users/#{user_id}/visit")
      .and_return Stub.json({})
  end

  context 'when opening in an iframe' do
    let(:provider) { create(:lti_provider, :iframe, domain: 'http://localhost:11000') }

    it 'renders the iframe with the LTI tool inside the course layout' do
      visit "/courses/the_course/items/#{item.id}"

      click_on 'Launch exercise tool'

      expect(page).to have_content item.title

      # If we see the item navigation again, we can assume to still see the course layout
      expect(page).to have_css "nav[data-controller~='course-item-nav']"

      iframe = find('iframe')

      # Allow full-screen interactivity for LTI tools (e.g. video players)
      expect(iframe[:allow]).to include 'fullscreen'

      within_frame iframe do
        expect(page).to have_content 'Welcome to LTI!'
      end
    end

    context 'when it is not a graded exercise' do
      let(:exercise_type) { '' }

      it 'skips the intro page and renders the iframe' do
        visit "/courses/the_course/items/#{item.id}"

        expect(page).to have_no_button 'Launch exercise tool'
        expect(page).to have_css "nav[data-controller~='course-item-nav']"
      end
    end
  end

  context 'when opening in the full window' do
    let(:provider) { create(:lti_provider, :window, domain: 'http://localhost:11000') }

    it 'opens to the LTI tool in a new window' do
      visit "/courses/the_course/items/#{item.id}"

      lti_window = window_opened_by do
        click_on 'Launch exercise tool'
      end

      within_window(lti_window) do
        expect(page).to have_content 'Welcome to LTI!'

        # No course layout, no custom header
        expect(page).to have_no_content item.title
        expect(page).to have_no_selector "nav[data-controller~='course-item-nav']"
      end
    end
  end

  context 'when the LTI provider has been deleted' do
    # Simulate orphaned exercise pointing to a deleted provider
    before { exercise.update_column(:lti_provider_id, nil) }

    it 'shows a proper error message' do
      visit "/courses/the_course/items/#{item.id}"

      expect(page).to have_content 'This exercise is not available anymore.'
    end
  end

  context 'with instructions' do
    let(:provider) { create(:lti_provider, :iframe, domain: 'http://localhost:11000') }
    let(:exercise) { create(:lti_exercise, :with_instructions, provider:) }

    context 'has an intro page' do
      it 'renders the instructions only once' do
        visit "/courses/the_course/items/#{item.id}"

        expect(page).to have_content 'Instructions'
        expect(page).to have_content 'Launch the tool and submit your results'

        click_on 'Launch exercise tool'

        expect(page).to have_no_content 'Launch the tool and submit your results'
      end
    end

    context 'has no intro page' do
      let(:exercise_type) { '' }

      it 'renders the instructions without a heading' do
        visit "/courses/the_course/items/#{item.id}"

        expect(page).to have_no_content 'Instructions'
        expect(page).to have_content 'Launch the tool and submit your results'
      end
    end
  end
end
