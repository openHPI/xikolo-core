# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Enrollment do
  subject(:enrollment) { create(:'course_service/enrollment', course: create(:'course_service/course', :self_paced)) }

  context 'validation' do
    let(:user) { create(:'account_service/user') }
    let(:course) { create(:'course_service/course') }

    it 'does not allow duplicate user and course combinations' do
      create(:'course_service/enrollment', user:, course:)
      expect do
        create(:'course_service/enrollment', user:, course:)
      end.to raise_error ActiveRecord::RecordInvalid
    end

    context 'with external course' do
      let(:course) { create(:'course_service/course', :external) }

      it 'does not create an enrollment' do
        expect do
          create(:'course_service/enrollment', user:, course:)
        end.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  context '(update course progress worker)' do
    subject(:enrollment) { build(:'course_service/enrollment') }

    it 'starts worker for a newly created enrollment to determine the user\'s course goals (max visits and points)' do
      expect { enrollment.save }.to have_enqueued_job(CourseService::LearningEvaluation::UpdateCourseProgressJob).exactly(:once)
    end
  end

  describe 'scopes' do
    describe 'for_current_course' do
      subject { CourseService::Enrollment.for_current_course.pluck(:id) }

      before do
        enrollment

        # Two other enrollments in courses that have ended
        create(:'course_service/enrollment', course: create(:'course_service/course', :self_paced))
        create(:'course_service/enrollment', course: create(:'course_service/course', :self_paced))
      end

      let!(:enrollment_course_active) do
        create(:'course_service/enrollment', course: create(:'course_service/course', :active))
      end

      it { is_expected.to eq [enrollment_course_active.id] }
    end
  end

  describe 'last visit' do
    subject { enrollment.last_visit }

    let(:section1) { create(:'course_service/section', course: enrollment.course, position: 1, start_date: 10.days.ago.iso8601) }
    let(:item11) { create(:'course_service/item', section: section1, position: 1) }
    let(:item12) { create(:'course_service/item', section: section1, position: 2) }
    let(:visit11) { create(:'course_service/visit', item: item11, user_id: enrollment.user_id, updated_at: 2.days.ago.iso8601) }
    let(:visit12) { create(:'course_service/visit', item: item12, user_id: enrollment.user_id, updated_at: 1.day.ago.iso8601) }

    context 'without item visits' do
      it { is_expected.to be_nil }
    end

    context 'with consecutive item visits' do
      before { visit11; visit12 }

      it { is_expected.to eq visit12 }
    end

    context 'with repeated item visits' do
      let(:visit12_date_update) { 6.hours.ago.iso8601 }

      before do
        visit11; visit12
        visit12.updated_at = visit12_date_update
        visit12.save
      end

      it { is_expected.to eq visit12 }
    end
  end
end
