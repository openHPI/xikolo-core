# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Enrollments: Create', type: :request do
  let(:user) { create('account_service/user') }
  let(:params) { {course_id: course.id} }
  let(:course) { create(:'course_service/course') }

  before { sign_in(user:) }

  describe 'via POST' do
    subject(:action) do
      post '/enrollments', params:
    end

    let(:course_group) { AccountService::Group.find_by!(name: course.students_group_name) }

    context 'when the user is not yet enrolled' do
      it 'redirects to the course details page' do
        action
        expect(response).to redirect_to course_path course.course_code
      end

      it 'creates an enrollment' do
        expect { action }.to change(CourseService::Enrollment, :count).by(1)
      end
    end

    context 'when the user is already enrolled' do
      before do
        create(:'course_service/enrollment', user_id: user.id, course:)
      end

      it 'redirects to the course content' do
        action
        expect(response).to redirect_to course_resume_path course.course_code
      end

      it 'does not create another enrollment' do
        expect { action }.not_to change(CourseService::Enrollment, :count)
      end
    end

    context 'when the server does not accept the enrollment' do
      context 'because the course is restricted to other user groups' do
        before { course.update(groups: ['foo']) }

        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to "/learn/#{course['course_code']}"
        end

        it 'does not create another enrollment' do
          expect { action }.not_to change(CourseService::Enrollment, :count)
        end
      end
    end

    context 'for an invite-only course' do
      let(:course) { create(:'course_service/course', :invite_only) }

      context 'as a regular user' do
        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to course_path course['course_code']
        end

        it 'does not create an enrollment' do
          expect { action }.not_to change(CourseService::Enrollment, :count)
        end
      end

      context 'with teaching rights' do
        before do
          role = create(:'account_service/role', permissions: %w[course.content.access])
          create(:'account_service/grant', principal: user, role:)
          create(:'account_service/membership', user:, group: course_group)
        end

        it 'redirects to the course details page' do
          action
          expect(response).to redirect_to "/learn/#{course.course_code}"
        end

        it 'creates an enrollment' do
          expect { action }.to change(CourseService::Enrollment, :count).by(1)
        end
      end
    end

    context 'without course ID' do
      let(:params) { {} }

      it 'responds with 404 Not Found' do
        expect { action }.to raise_error AbstractController::ActionNotFound
      end
    end
  end

  # HACK: Enrollment via GET is allowed as well
  describe 'via GET' do
    subject(:action) do
      get '/enrollments', params:
    end

    context 'when the user is not yet enrolled' do
      it 'redirects to the course details page' do
        action
        expect(response).to redirect_to "/learn/#{course.course_code}"
      end

      it 'creates an enrollment' do
        expect { action }.to change(CourseService::Enrollment, :count).by(1)
      end
    end

    context 'without course ID' do
      let(:params) { {} }

      it 'responds with 404 Not Found' do
        expect { action }.to raise_error AbstractController::ActionNotFound
      end
    end
  end
end
