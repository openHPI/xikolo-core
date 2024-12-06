# frozen_string_literal: true

require 'spec_helper'

describe Proctoring::CourseContext do
  subject(:proctoring_context) { described_class.new(course, enrollment) }

  let(:user_id) { generate(:user_id) }
  let(:course) do
    Xikolo::Course::Course.new build(:'course:course', :current, :proctored)
  end
  let(:enrollment) do
    Xikolo::Course::Enrollment.new(
      build(:'course:enrollment', :proctored, user_id:, course_id: course.id)
    )
  end

  describe '#upgrade_possible?' do
    let(:items) { [] }

    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(
        :course, :get, '/items',
        query: {course_id: course.id,
               content_type: 'quiz',
               exercise_type: 'main',
               proctored: true,
               published: true,
               state_for: user_id}
      ).to_return Stub.json(items)
    end

    context 'w/o any quiz item (exam)' do
      it { is_expected.to be_upgrade_possible }
    end

    context 'w/ exactly one quiz item (exam)' do
      let(:item_user_state) { 'new' }
      let(:submission_deadline) { 1.week.from_now }
      let(:start_date) { 1.week.ago }
      let(:items) do
        [{
          user_state: item_user_state,
          submission_deadline:,
          start_date:,
        }]
      end

      context 'w/ quiz item available (not submitted nor deadline passed)' do
        it { is_expected.to be_upgrade_possible }
      end

      context 'w/ quiz item submitted' do
        let(:item_user_state) { 'submitted' }

        it { is_expected.not_to be_upgrade_possible }
      end

      context 'w/ quiz item missed' do
        let(:submission_deadline) { 1.day.ago }

        it { is_expected.not_to be_upgrade_possible }
      end
    end

    context 'w/ multiple quiz items (exams)' do
      let(:item_user_state) { 'new' }
      let(:submission_deadline) { 1.week.from_now }
      let(:start_date) { 2.weeks.ago }
      let(:item_user_state_2) { 'new' }
      let(:submission_deadline_2) { 2.weeks.from_now }
      let(:start_date_2) { 1.week.ago }
      let(:items) do
        [{
          user_state: item_user_state,
          submission_deadline:,
          start_date:,
        }, {
          user_state: item_user_state_2,
          submission_deadline: submission_deadline_2,
          start_date: start_date_2,
        }]
      end

      context 'w/ quiz items available' do
        it { is_expected.to be_upgrade_possible }
      end

      context 'w/ proctoring upgrading deadline close' do
        let(:submission_deadline) { 2.days.from_now }
        let(:submission_deadline_2) { 3.days.from_now }

        it { is_expected.to be_upgrade_possible }
      end

      context 'w/ proctoring upgrading deadline missed' do
        let(:submission_deadline) { 1.day.from_now }
        let(:submission_deadline_2) { 2.days.from_now }

        it { is_expected.not_to be_upgrade_possible }
      end

      context 'w/ one quiz item missed only' do
        let(:submission_deadline) { 1.week.ago }

        it { is_expected.to be_upgrade_possible }
      end

      context 'w/ one item missed but another upcoming' do
        let(:submission_deadline) { 1.day.ago }
        let(:submission_deadline_2) { 10.days.from_now }
        let(:start_date) { 1.week.ago }
        let(:start_date_2) { 5.days.from_now }

        it { is_expected.to be_upgrade_possible }
      end

      context 'w/ more than one quiz item missed' do
        let(:submission_deadline) { 7.days.ago }
        let(:submission_deadline_2) { 5.days.ago }

        it { is_expected.not_to be_upgrade_possible }
      end

      context 'w/ more than one quiz item submitted' do
        let(:item_user_state) { 'graded' }
        let(:item_user_state_2) { 'submitted' }

        it { is_expected.not_to be_upgrade_possible }
      end

      context 'w/ more than one quiz item missed or submitted' do
        let(:submission_deadline) { 1.week.ago }
        let(:item_user_state_2) { 'submitted' }

        it { is_expected.not_to be_upgrade_possible }
      end

      context 'for a self-paced course' do
        let(:course) do
          Xikolo::Course::Course.new(
            build(:'course:course', :self_paced, :proctored)
          )
        end

        it { is_expected.to be_upgrade_possible }
      end

      context 'for an upcoming course' do
        let(:course) do
          Xikolo::Course::Course.new(
            build(:'course:course', :upcoming, :proctored)
          )
        end

        it { is_expected.to be_upgrade_possible }
      end

      context 'for an archived course offering both proctoring and reactivation' do
        let(:course) { create(:course, :archived, :offers_proctoring, :offers_reactivation) }
        let(:enrollment) { create(:enrollment, course:, user_id:) }
        let(:items) do
          [{
            user_state: item_user_state,
            submission_deadline: 1.week.ago,
            start_date:,
          },
           {
             user_state: item_user_state2,
             submission_deadline: 1.week.ago,
             start_date:,
           }]
        end
        let(:item_user_state) { 'new' }
        let(:item_user_state2) { 'new' }

        context 'w/ reactivation not booked' do
          it { is_expected.not_to be_upgrade_possible }
        end

        context 'w/ the course reactivated for the user' do
          let(:enrollment) do
            create(:enrollment, :reactivated, course:, user_id:)
          end

          context 'with no submissions' do
            it { is_expected.to be_upgrade_possible }
          end

          context 'w/ only one submission' do
            let(:item_user_state) { 'submitted' }

            it { is_expected.to be_upgrade_possible }
          end

          context 'w/ more than one submission' do
            let(:item_user_state) { 'submitted' }
            let(:item_user_state2) { 'submitted' }

            it { is_expected.not_to be_upgrade_possible }
          end
        end
      end
    end
  end
end
