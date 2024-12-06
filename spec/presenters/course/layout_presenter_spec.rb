# frozen_string_literal: true

require 'spec_helper'

describe Course::LayoutPresenter do
  subject(:presenter) { described_class.new course, user }

  let(:course_id) { generate(:course_id) }
  let(:course_params) { {id: course_id} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:user_id) { generate(:user_id) }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'user_id' => user_id,
      'user' => {'anonymous' => false}
    )
  end
  let(:permissions) { [] }

  describe '#nav' do
    it 'has a pinboard item by default' do
      expect(presenter.nav.map(&:text)).to include('Discussions')
    end

    context 'with disabled pinboard' do
      let(:course_params) { super().merge(pinboard_enabled: false) }

      it 'has no pinboard item' do
        expect(presenter.nav.map(&:text)).not_to include('Discussions')
      end
    end
  end

  describe '#teacher_nav' do
    subject { super().teacher_nav }

    context 'without user' do
      let(:user) { anonymous }

      it { is_expected.to be_empty }
    end

    context 'with a student' do
      it { is_expected.to be_empty }
    end

    context 'with course.dashboard.view' do
      let(:permissions) { ['course.dashboard.view'] }

      it { is_expected.not_to be_empty }
    end

    context 'with course.course.edit' do
      let(:permissions) { ['course.course.edit'] }

      it { is_expected.not_to be_empty }
    end

    context 'with course.permissions.view' do
      let(:permissions) { ['course.permissions.view'] }

      it { is_expected.to be_empty }

      context 'with course.course.edit' do
        let(:permissions) { ['course.course.edit'] }

        # The permissions item is nested in the course settings item
        it { is_expected.not_to be_empty }
      end
    end

    context 'with course.content.edit' do
      let(:permissions) { ['course.content.edit'] }

      it { is_expected.not_to be_empty }
    end

    context 'with course.enrollment.index' do
      let(:permissions) { ['course.enrollment.index'] }

      it { is_expected.not_to be_empty }
    end

    context 'with quiz.submission.index' do
      let(:permissions) { ['quiz.submission.index'] }

      it { is_expected.not_to be_empty }
    end
  end

  context 'deadlines' do
    subject(:deadlines) { presenter.deadlines }

    let(:dates) { [{}] }

    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(
        :course, :get, '/next_dates',
        query: {
          all: 'true',
          course_id:,
          user_id:,
          type: 'item_submission_deadline,on_demand_expires',
        }
      ).to_return Stub.json(dates)
    end

    context 'without user' do
      let(:user) { anonymous }

      it { is_expected.not_to be_show }
      it { is_expected.not_to be_any }
    end

    context 'with user' do
      before { expect(user).not_to be_anonymous }

      it { is_expected.to be_show }
      it { is_expected.to be_any }
      it { expect(deadlines.count).to be(1) }
    end
  end

  describe '#needs_recalculation?' do
    subject(:needs_recalculation) { presenter.send(:needs_recalculation?) }

    context 'by default' do
      # PLE config option is false by default
      it { is_expected.to be false }
    end

    context 'with enabled persisted learning evaluation' do
      let(:the_course) { create(:course, course_params) }
      let(:course_params) { {id: course_id, progress_calculated_at: 1.week.ago} }

      before do
        xi_config <<~YML
          persisted_learning_evaluation: true
        YML

        the_course
      end

      context 'without sufficient permissions' do
        it { is_expected.to be false }
      end

      context 'with sufficient permissions' do
        let(:permissions) { %w[course.course.recalculate] }

        context 'with the course progress not yet calculated' do
          let(:course_params) { super().merge(progress_calculated_at: nil) }

          it { is_expected.to be true }
        end

        context 'for a node not marked for recalculation' do
          it { is_expected.to be false }
        end

        context 'for a node marked for recalculation' do
          before do
            the_course.node.update! progress_stale_at: 1.hour.ago
          end

          it { is_expected.to be true }
        end

        context 'for legacy courses' do
          let(:the_course) { create(:course_legacy, course_params) }

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
end
