# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Show', type: :request do
  subject(:show_course) do
    get '/courses/the-course', headers:
  end

  let(:headers) { {} }
  let(:course) { create(:course, course_code: 'the-course') }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code)
  end
  let(:page) { Capybara::Node::Simple.new(response.body) }

  before do
    Stub.request(
      :course, :get, '/courses/the-course'
    ).to_return Stub.json(course_resource)
  end

  context 'for anonymous user' do
    it 'redirects to the dashboard' do
      show_course
      expect(response).to redirect_to dashboard_path
    end

    context '(non-public course page)' do
      before do
        xi_config <<~YML
          public_course_page:
            enabled: false
            url_template: 'https://portal.example.com/courses{/course_code}'
        YML
      end

      it 'redirects to the corresponding portal' do
        show_course
        expect(response).to redirect_to 'https://portal.example.com/courses/the-course'
      end

      context 'with invalid configuration' do
        before do
          xi_config <<~YML
            public_course_page:
              enabled: false
          YML
        end

        it 'redirects to the dashboard' do
          show_course
          expect(response).to redirect_to dashboard_path
        end
      end
    end
  end

  context 'for logged-in user' do
    let!(:user) { stub_user_request permissions: %w[course.course.show course.content.access] }
    let(:headers) { super().merge('Authorization' => "Xikolo-Session session_id=#{stub_session_id}") }
    let(:course_actions) { page.find(:xpath, "//div[contains(@class, 'course-actions')]") }

    before do
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(user_id: user[:id], course_id: course.id)
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/sections',
        query: {course_id: course.id}
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/items',
        query: hash_including(course_id: course.id)
      ).to_return Stub.json([])
      Stub.request(
        :course, :get, '/stats',
        query: hash_including(course_id: course.id, key: 'enrollments')
      ).to_return Stub.json({enrollments: 9999})
      Stub.request(
        :course, :get, '/teachers',
        query: {course: course.id}
      ).to_return Stub.json([{id: SecureRandom.uuid, name: 'Jane Doe'}])
    end

    it 'shows the course page' do
      show_course
      expect(response).to be_successful
    end

    it 'shows an enrollment button' do
      show_course
      expect(course_actions).to have_link('Enroll me for this course')
    end

    context 'for enrolled user' do
      let(:deleted) { false }

      before { create(:enrollment, course_id: course.id, user_id: user[:id], deleted:) }

      it 'shows resume and un-enroll buttons' do
        show_course
        expect(course_actions).to have_link('Enter course')
        expect(course_actions).to have_link('Un-enroll')
      end

      it 'shows links to show progress and resume the course' do
        show_course
        expect(page).to have_link('Show my progress', href: "/courses/#{course.course_code}/progress")
        expect(page).to have_link('Enter course', href: "/courses/#{course.course_code}/resume")
      end

      context 'with deleted enrollment' do
        let(:deleted) { true }

        it 'shows an enrollment button' do
          show_course
          expect(course_actions).to have_link('Enroll me for this course')
        end
      end
    end

    context '(non-public course page)' do
      before do
        xi_config <<~YML
          public_course_page:
            enabled: false
            url_template: 'https://portal.example.com/courses{/course_code}'
        YML
      end

      it 'shows the course page' do
        show_course
        expect(response).to be_successful
      end
    end
  end
end
