# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Progress: Bar', type: :request do
  subject(:show_bar) do
    get "/learn/#{course.course_code}/progress/bar"
  end

  let(:course) { create(:course) }

  context 'for anonymous user' do
    it 'redirects the user' do
      show_bar
      expect(response).to redirect_to "/learn/#{course.course_code}"
    end
  end

  context 'for an enrolled user' do
    let(:user) { create(:'account_service/user') }
    let(:page) { Capybara.string(response.body) }

    before do
      role = create(:'account_service/role', permissions: %w[course.content.access.available])
      create(:'account_service/grant', principal: user, role:)
      sign_in(user:)

      section = create(:'course_service/section', course:)
      items = create_list(:'course_service/item', 4, section:)
      create(:'course_service/visit', item: items.first, user:)
    end

    it 'renders the progress bar in its frame, without the layout' do
      show_bar

      expect(response).to have_http_status :ok
      expect(page).to have_css('turbo-frame#course-progress progress[value="25"]')
      expect(page).to have_text '25%'
      expect(page).to have_no_css('#maincontent')
    end
  end
end
