# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Details', type: :request do
  subject(:show_course) do
    get '/learn/the-course', headers:
  end

  # We build this spec for a logged-in user since the anonymous user does not come with the default permissions. (course.course.show)
  let(:headers) { {} }
  let(:user) { create(:'account_service/user') }
  let(:page) { Capybara::Node::Simple.new(response.body) }
  let(:permissions) { %w[course.course.show] }
  let(:course) { create(:course, course_code: 'the-course') }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }

  before do
    sign_in(user:)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)

    Stub.request(
      :course, :get, '/courses/the-course'
    ).to_return Stub.json(course_resource)
  end

  it 'shows the course overview' do
    show_course

    expect(response).to be_successful
    expect(page.find('[data-testid="course-details-card"]')).to have_text(course.title)
  end

  context 'with current enrollment totals' do
    before { course.update!(enrollment_delta: count) }

    let(:count) { 499 }

    it 'hides small totals' do
      show_course

      expect(page.find('[data-testid="course-details-card"]')).to have_no_text('499 enrollments')
    end

    context 'at the public visibility threshold' do
      let(:count) { 500 }

      it 'shows the current total in the details card' do
        show_course

        expect(page.find('[data-testid="course-details-card"]')).to have_text('500 enrollments')
      end
    end

    context 'with permission to view smaller totals' do
      let(:permissions) { super() + %w[course.enrollment_counter.view] }

      it 'shows the current total in the details card' do
        show_course

        expect(page.find('[data-testid="course-details-card"]')).to have_text('499 enrollments')
      end
    end
  end

  context 'with an invitation-only course' do
    let(:course) { create(:course, course_code: 'the-course', invite_only: true) }

    it 'does not offer self-enrollment' do
      show_course

      expect(response).to be_successful
      expect(page).to have_no_link('Enroll now')
      expect(page).to have_no_link('Enroll for the course')
    end
  end

  context 'with an external course' do
    let(:course) { create(:course, course_code: 'the-course', external_course_url: 'https://example.org/course') }

    it 'links to the external course' do
      show_course

      expect(response).to be_successful
      expect(page).to have_link(href: 'https://example.org/course')
    end
  end
end
