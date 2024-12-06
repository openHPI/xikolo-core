# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Statistics: Courses', type: :request do
  subject(:show_courses) { get '/admin/statistics/courses', headers: }

  let(:cluster) { create(:cluster, id: 'reporting') }
  let(:cluster2) { create(:cluster, id: 'topic') }
  let!(:classifier) { create(:classifier, title: 'dashboard', cluster_id: cluster.id) }
  let!(:wrong_classifier) { create(:classifier, title: 'dashboard', cluster_id: cluster2.id) }
  let(:wrong_course) do
    create(:course, title: 'Course not shown', course_code: 'not-shown',
      start_date: 1.week.ago, end_date: 1.week.from_now)
  end
  let(:course_shown) do
    create(:course, title: 'Course 1', course_code: 'course-1',
      start_date: 1.week.ago, end_date: 1.week.from_now)
  end

  context 'as anonymous user' do
    it 'redirects the user' do
      show_courses
      expect(response).to redirect_to root_url
    end
  end

  context 'as logged in user' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { [] }

    before { stub_user_request permissions: }

    it 'redirects the user' do
      show_courses
      expect(response).to redirect_to root_url
    end

    context 'with permissions' do
      let(:permissions) { %w[global.dashboard.show] }

      before do
        Stub.service(:learnanalytics, build(:'lanalytics:root'))
        Stub.request(
          :learnanalytics, :get, '/metrics/certificates',
          query: {course_id: course_shown.id}
        ).to_return Stub.json({
          'record_of_achievement' => 3,
          'confirmation_of_participation' => 6,
          'qualified_certificate' => 0,
        })

        wrong_course.classifiers << wrong_classifier
        wrong_course.save!
      end

      context "with the 'dashboard' classifier assigned to the course" do
        before do
          students = create_list(:user, 7)
          students.each do |student|
            create(:enrollment, user_id: student.id, course_id: course_shown.id)
          end

          section = create(:section, course: course_shown)
          item = create(:item, section:)
          students[0..5].each do |student|
            create(:visit, item:, user: student, created_at: 6.days.ago)
          end

          course_shown.classifiers << classifier
          course_shown.save!
        end

        it 'displays the course overview table' do
          show_courses

          expect(response).to have_http_status :ok
          expect(response.body).to include 'Course 1'
          expect(response.body).to include 'course-1'
          expect(response.body).to include '6 CoPs'
          expect(response.body).to include '3 RoAs'
          expect(response.body).to include '7 enrollments'
          expect(response.body).to include '6 shows at middle'
          expect(response.body).to include '50%'
          expect(response.body).not_to include 'Course not shown'
          expect(response.body).not_to include 'not-shown'
        end
      end

      context 'without any course that has a dashboard classifier' do
        it 'displays an empty state' do
          show_courses

          expect(response).to have_http_status :ok
          expect(response.body).not_to include 'not-shown'
          expect(response.body).not_to include 'course-1'
          expect(response.body).to include 'An overview of courses with the "dashboard" tag in the "reporting" category will appear here.'
        end
      end
    end
  end
end
