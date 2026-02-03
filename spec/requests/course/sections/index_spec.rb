# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Sections: Index', type: :request do
  subject(:request) do
    get "/courses/#{course.course_code}/sections", headers:
  end

  let!(:group) { create(:group, course:) }
  let!(:stub_course) { build(:'course:course', course_code: 'course_1') }
  let!(:stub_section) { build(:'course:section', course_id: stub_course['id']) } # rubocop:disable RSpec/LetSetup
  let!(:course) { create(:course, id: stub_course['id'], course_code: 'course_1') }

  let(:content_test) { create(:content_test, course:, identifier: 'Gamification') }
  let!(:section) { create(:section, title: 'Week 1', course:) }
  let!(:fork) { create(:fork, section:, content_test:) }
  let(:branch) { create(:branch, group_id: group.id, fork:) }

  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request(id: user_id, permissions:)
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id: stub_course['id'], user_id:}
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including(course_id: stub_course['id'])
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, '/courses/course_1'
    ).to_return Stub.json(stub_course)
  end

  context 'as logged in course admin' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:user_id) { generate(:user_id) }
    let(:permissions) { %w[course.content.access course.content.edit] }

    it 'displays the fork' do
      request
      expect(response).to be_successful
      expect(page).to have_content 'Week 1'
      expect(page).to have_content 'Fork'
      expect(page).to have_content 'Gamification'
    end

    context 'with section and item end date in past' do
      let(:section1) { create(:section, title: 'Week 2', course:, start_date: '2020-01-01', end_date: '2020-01-02') }
      let(:item) { create(:item, :video, title: 'Item 1', section: section1, start_date: '2020-01-01', end_date: '2020-01-02') }

      before do
        section1
        item
      end

      it 'shows when the section was locked' do
        request
        expect(page).to have_content 'Week 2'
        expect(page).to have_content 'Was locked on 02 Jan'
      end

      it 'shows when the item was locked' do
        request
        expect(page).to have_content 'Item 1'
        expect(page).to have_content 'Item was locked 02 Jan'
      end
    end

    context 'with section and item start date in future' do
      let(:section1) { create(:section, title: 'Week 2', course:, start_date: 1.day.from_now, end_date: 2.days.from_now) }
      let(:item) { create(:item, :video, title: 'Item 1', section:, start_date: 1.day.from_now, end_date: 2.days.from_now) }

      before do
        section1
        item
      end

      it 'shows when the section will be unlocked' do
        request
        expect(page).to have_content 'Week 2'
        expect(page).to have_content 'Will be unlocked on'
      end

      it 'shows when the item will be unlocked' do
        request
        expect(page).to have_content 'Item 1'
        expect(page).to have_content 'Item will be unlocked in'
      end
    end

    context 'with section and item start date in past and end date in future' do
      let(:section1) { create(:section, title: 'Week 2', course:, start_date: '2020-01-01', end_date: 1.day.from_now) }
      let(:item) { create(:item, :video, title: 'Item 1', section:, start_date: 1.day.ago, end_date: 1.day.from_now) }

      before do
        section1
        item
      end

      it 'shows when the section was unlocked' do
        request
        expect(page).to have_content 'Week 2'
        expect(page).to have_content 'Was unlocked on 01 Jan'
      end

      it 'shows when the item will be locked' do
        request
        expect(page).to have_content 'Item 1'
        expect(page).to have_content 'Item will be locked on'
      end
    end
  end
end
