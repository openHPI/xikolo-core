# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Show', type: :request do
  subject(:show_course) do
    get '/learn/the-course'
  end

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
    let!(:user) { create(:'account_service/user') }
    let(:permissions) { %w[course.course.show course.content.access] }
    let(:course_actions) { page.find('[data-testid="course-details-card"]') }

    before do
      sign_in(user:)
      role = create(:'account_service/role', permissions:)
      create(:'account_service/grant', principal: user, role:)
    end

    it 'shows the course page' do
      show_course
      expect(response).to be_successful
    end

    it 'shows an enrollment button' do
      show_course
      expect(course_actions).to have_link('Enroll now')
      expect(page).to have_no_link('Mark as completed')
    end

    context 'for enrolled user' do
      let(:deleted) { false }
      let(:completed) { false }

      before { create(:enrollment, course_id: course.id, user_id: user.id, deleted:, completed:) }

      it 'shows resume and un-enroll buttons' do
        show_course
        expect(course_actions).to have_link('Continue course')
        expect(course_actions).to have_link('Un-enroll')
      end

      it 'provides progress navigation and a resume action in the details card' do
        show_course
        expect(page).to have_link('Progress', href: "/learn/#{course.course_code}/progress")
        expect(course_actions).to have_link('Continue course', href: "/learn/#{course.course_code}/resume")
      end

      it 'offers manual completion using the existing POST and confirmation' do
        show_course

        expect(course_actions).to have_link('Mark as completed')
        link = course_actions.find_link('Mark as completed')
        expect(link['data-method']).to eq('post')
        expect(link['data-confirm']).to eq(I18n.t(:'dashboard.mark_completed_confirmation'))
      end

      context 'with a completed enrollment' do
        let(:completed) { true }

        it 'does not offer manual completion' do
          show_course

          expect(page).to have_no_link('Mark as completed')
        end
      end

      context 'with an earned achievement' do
        let(:completed) { nil }

        before do
          course.update!(records_released: true, roa_enabled: true, roa_threshold_percentage: 50)
          create(:'course_service/course_progress', course:, user_id: user.id,
            main_dpoints: 80, max_dpoints: 100, points_percentage_fpoints: 8000)
        end

        it 'does not offer manual completion for an automatically completed course' do
          show_course

          expect(page).to have_no_link('Mark as completed')
        end
      end

      context 'with an upcoming course' do
        let(:course) { create(:course, :upcoming, course_code: 'the-course') }

        it 'does not offer manual completion' do
          show_course

          expect(page).to have_no_link('Mark as completed')
        end
      end

      context 'with an upcoming display date' do
        before { course.update!(display_start_date: 1.week.from_now) }

        it 'does not offer manual completion before its displayed start' do
          show_course

          expect(page).to have_no_link('Mark as completed')
        end
      end

      context 'with deleted enrollment' do
        let(:deleted) { true }

        it 'shows an enrollment button' do
          show_course
          expect(course_actions).to have_link('Enroll now')
          expect(page).to have_no_link('Mark as completed')
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
