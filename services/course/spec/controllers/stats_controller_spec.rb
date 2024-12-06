# frozen_string_literal: true

require 'spec_helper'

describe StatsController, type: :controller do
  let(:json) { request.call; JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:request) { -> { get :show, params: } }
  let(:params) { {key: 'enrollments', course_id: course.id} }

  let(:course) { create(:course, course_params) }
  let(:course_params) { {} }

  before do
    create(:course)
    create(:fixed_learning_evaluation, course:)
    create_list(:enrollment, 3, course_id: course.id, created_at: course.start_date - 1)
    create_list(:enrollment, 2, course_id: course.id, created_at: course.end_date - 1)
  end

  describe 'response' do
    subject { request.call; response }

    its(:status) { is_expected.to eq 200 }
  end

  describe 'body' do
    subject { json }

    its(['student_enrollments']) { is_expected.to be 5 }
    it { is_expected.to include 'student_enrollments_at_start' }
    it { is_expected.to include 'student_enrollments_at_end' }
    it { is_expected.not_to include 'exam_participants' }

    describe 'enrollments by day' do
      subject { json['student_enrollments_by_day'] }

      let(:params) { super().merge key: 'enrollments_by_day' }

      its(:size) { is_expected.to be 47 } # that is the max delta of all enrollment dates
    end

    describe 'global delta enrollment' do
      let(:params) { super().merge key: 'global' }
      let(:course_params) { super().merge enrollment_delta: 7 }

      its(['platform_enrollment_delta_sum']) { is_expected.to be 7 }
      its(['unenrollments']) { is_expected.to be 0 }
      its(['platform_custom_completed']) { is_expected.to be 0 }
    end

    describe 'percentile_created_at_days' do
      subject { json['percentile_created_at_days'] }

      let(:params) { super().merge key: 'percentile_created_at_days' }

      its(:size) { is_expected.to be 1 } # that is the max delta of all enrollment dates
    end

    context 'with extended stats' do
      let(:params) { super().merge key: 'extended' }

      context 'with end date in the future' do
        let(:course_params) { super().merge start_date: 1.week.ago, end_date: 1.week.from_now }

        its(['new_users']) { is_expected.to be 5 }
        it { is_expected.not_to include 'student_enrollments_at_end' }
        it { is_expected.not_to include 'exam_participants' }
      end

      context 'with end date in the past' do
        let(:course_params) { super().merge start_date: 1.week.ago, end_date: 1.hour.ago, middle_of_course: 3.days.ago }

        its(['student_enrollments_at_start']) { is_expected.to be 3 }
        its(['student_enrollments_at_middle']) { is_expected.to be 3 }
        its(['student_enrollments_at_end']) { is_expected.to be 5 }
        its(['exam_participants']) { is_expected.to be_nil }
      end
    end

    context 'with shows and no shows stats' do
      let(:params) { super().merge key: 'shows_and_no_shows' }

      context 'with end date in the past' do
        let(:course_params) { super().merge start_date: 2.weeks.ago, end_date: 1.week.ago }
        let(:section) { create(:section, course_id: course.id) }

        before do
          item = create(:item, section:)
          enrollment = create(:enrollment, course:, created_at: 8.days.ago)
          recent_enrollment = create(:enrollment, course:, created_at: 2.days.ago)
          create(:visit, item:, user_id: enrollment.user_id, created_at: enrollment.created_at)
          create(:visit, item:, user_id: recent_enrollment.user_id, created_at: recent_enrollment.created_at)
        end

        its(['shows_at_end']) { is_expected.to be 1 }
        its(['shows']) { is_expected.to be 2 }
      end
    end
  end
end
