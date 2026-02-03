# frozen_string_literal: true

require 'spec_helper'

describe 'Courses: Course list banner', type: :request do
  subject(:get_courses) { get '/courses', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request features: {'course_list' => 'true'}

    Stub.request(:course, :get, '/courses/')
      .to_return Stub.json([])
    Stub.request(
      :course, :get, '/api/v2/course/courses',
      query: hash_including(embed: 'enrollment')
    ).to_return Stub.json([])
  end

  context 'with no banner configured' do
    it 'does not show banner content on the course list' do
      get_courses

      expect(response.body).not_to include 'course-list-banner'
    end
  end

  context 'with a banner linking to a URL, opening in the same tab' do
    before do
      create(:banner, publish_at: 1.day.from_now, alt_text: 'Upcoming banner')
      create(:banner, publish_at: 1.week.ago, alt_text: 'Current banner')
    end

    it 'shows the current banner on the course list' do
      get_courses

      expect(response.body).to include 'course-list-banner'
      expect(page).to have_css 'a[href="https://www.example.com"][target="_self"]'
      expect(page).to have_css 'img[alt="Current banner"]'
    end
  end

  context 'with a banner linking to a URL, opening in a new tab' do
    before do
      create(:banner, publish_at: 2.weeks.ago, expire_at: 1.day.ago, alt_text: 'Expired banner')
      create(:banner, publish_at: 1.week.ago, alt_text: 'Current banner', link_target: 'blank')
    end

    it 'shows the current banner on the course list' do
      get_courses

      expect(response.body).to include 'course-list-banner'
      expect(page).to have_css 'a[href="https://www.example.com"][target="_blank"]'
      expect(page).to have_css 'img[alt="Current banner"]'
    end
  end
end
