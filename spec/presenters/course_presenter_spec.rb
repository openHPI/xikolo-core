# frozen_string_literal: true

require 'spec_helper'

describe CoursePresenter do
  subject { presenter }

  let(:course_id) { generate(:course_id) }
  let(:completed) { false }
  let(:enrollment) { CourseService::Enrollment.new course_id: the_course.id, completed: }
  let(:course_params) { {} }
  let(:the_course) { create(:course, course_params) }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:user_id) { session.user.id }
  let(:permissions) { [] }
  let(:presenter) { described_class.create the_course, user, [enrollment] }

  before do
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: session.user, role:)
  end

  it { is_expected.not_to be_external }

  describe '#needs_recalculation?' do
    subject(:needs_recalculation) { presenter.needs_recalculation? }

    let(:course_params) { {id: course_id, progress_calculated_at: 1.week.ago} }

    before do
      the_course
    end

    context 'without sufficient permissions' do
      it { is_expected.to be false }
    end

    context 'with sufficient permissions' do
      let(:permissions) { %w[course.course.recalculate] }

      context 'for a node not marked for recalculation' do
        it { is_expected.to be false }
      end

      context 'with the course progress not yet calculated' do
        let(:course_params) { super().merge(progress_calculated_at: nil) }

        it { is_expected.to be true }
      end

      context 'for a node marked for recalculation' do
        before do
          the_course.node.update! progress_stale_at: 1.hour.ago
        end

        it { is_expected.to be true }
      end

      context 'for legacy courses' do
        let(:the_course) { create(:course_legacy, course_params.merge(title: 'Legacy Course')) }

        context 'with the course progress not yet calculated' do
          let(:course_params) { super().merge(progress_calculated_at: nil) }

          it { is_expected.to be true }
        end

        context 'when not marked for recalculation' do
          it { is_expected.to be false }
        end

        context 'when marked for recalculation' do
          let(:course_params) { super().merge(progress_stale_at: 1.hour.ago) }

          it { is_expected.to be true }
        end
      end
    end
  end
end
