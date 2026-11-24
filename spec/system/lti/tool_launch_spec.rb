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

describe 'LTI: Tool Launch', type: :system do
  around do |example|
    lti_server = WEBrick::HTTPServer.new Port: 11_000, Log: false, AccessLog: []
    lti_server.mount '/', LtiServlet
    Thread.new { lti_server.start }

    example.run

    lti_server.shutdown
  end

  let(:user) { create(:'account_service/user') }
  let(:course) { create(:'course_service/course', :active, :with_content_tree) }
  let(:section) { create(:'course_service/section', course:) }
  let(:exercise) { create(:lti_exercise, provider:) }
  let(:provider) { create(:lti_provider, course_id: course.id) }
  let(:item) { create(:'course_service/item', section:, content: exercise, exercise_type:) }
  let(:exercise_type) { 'main' }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  context 'when opening in an iframe' do
    let(:provider) { create(:lti_provider, :iframe, domain: 'http://localhost:11000', course_id: course.id) }

    it 'renders the iframe with the LTI tool inside the course layout' do
      visit "/learn/#{course.course_code}/items/#{item.id}"

      within('nav[aria-label="Course actions"]') { click_on 'Launch exercise tool' }

      expect(page).to have_text item.title

      # If we see the course navigation menu, we can assume to still see the course layout
      expect(page).to have_css '#course-nav-drawer', visible: :all

      iframe = find('iframe')

      # Allow full-screen interactivity for LTI tools (e.g. video players)
      expect(iframe[:allow]).to include 'fullscreen'

      within_frame iframe do
        expect(page).to have_text 'Welcome to LTI!'
      end
    end

    context 'when it is not a graded exercise' do
      let(:exercise_type) { '' }

      it 'skips the intro page and renders the iframe' do
        visit "/learn/#{course.course_code}/items/#{item.id}"

        expect(page).to have_css '#course-nav-drawer', visible: :all
        expect(page).to have_no_button 'Launch exercise tool'
      end
    end
  end

  context 'when opening in the full window' do
    let(:provider) { create(:lti_provider, :window, domain: 'http://localhost:11000', course_id: course.id) }

    it 'opens to the LTI tool in a new window' do
      visit "/learn/#{course.course_code}/items/#{item.id}"

      within('nav[aria-label="Course actions"]') do
        expect(page).to have_css('a[target="_blank"][rel="noopener noreferrer"]', text: 'Launch exercise tool')
      end

      lti_window = window_opened_by do
        within('nav[aria-label="Course actions"]') { click_on 'Launch exercise tool' }
      end

      within_window(lti_window) do
        expect(page).to have_text 'Welcome to LTI!'

        # No course layout, no custom header
        expect(page).to have_no_text item.title
        expect(page).to have_no_css '#course-nav-drawer', visible: :all
      end
    end
  end

  context 'when the LTI provider has been deleted' do
    # Simulate orphaned exercise pointing to a deleted provider
    before { exercise.update_column(:lti_provider_id, nil) }

    it 'shows a proper error message' do
      visit "/learn/#{course.course_code}/items/#{item.id}"

      expect(page).to have_text 'This exercise is not available anymore.'
    end
  end

  context 'with instructions' do
    let(:provider) { create(:lti_provider, :iframe, domain: 'http://localhost:11000', course_id: course.id) }
    let(:exercise) { create(:lti_exercise, :with_instructions, provider:) }

    context 'has an intro page' do
      it 'renders the instructions only once' do
        visit "/learn/#{course.course_code}/items/#{item.id}"

        expect(page).to have_text 'Instructions'
        expect(page).to have_text 'Launch the tool and submit your results'

        within('nav[aria-label="Course actions"]') { click_on 'Launch exercise tool' }

        expect(page).to have_no_text 'Launch the tool and submit your results'
      end
    end

    context 'has no intro page' do
      let(:exercise_type) { '' }

      it 'renders the instructions without a heading' do
        visit "/learn/#{course.course_code}/items/#{item.id}"

        expect(page).to have_text 'Launch the tool and submit your results'
        expect(page).to have_no_text 'Instructions'
      end
    end
  end
end
