# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Progress', type: :request do
  subject(:show_progress) do
    get "/learn/#{course.course_code}/progress"
  end

  let(:request_context_id) { course_resource['context_id'] }
  let(:course) { create(:course, title: 'My Awesome Course', records_released: true) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code,
      title: 'My Awesome Course',
      context_id: AccountService::Context.root.id)
  end
  let(:progresses) { build(:'course:progresses') }

  before do
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .and_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects the user' do
      show_progress
      expect(response).to redirect_to "/learn/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end

  context 'for logged-in user' do
    let(:user) { create(:'account_service/user') }
    let(:user_id) { user.id }
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in(user:)
    end

    it 'redirects the user if not enrolled' do
      show_progress
      expect(response).to redirect_to "/learn/#{course.course_code}"
      expect(flash[:error].first).to eq 'You are not enrolled for this course.'
    end

    context 'when the user is enrolled in the course' do
      before do
        role = create(:'account_service/role', permissions: %w[course.content.access.available])
        create(:'account_service/grant', principal: user, role:)
      end

      it 'displays the course progress page' do
        show_progress
        expect(response.body).to include 'My learning progress'
      end
    end
  end
end
