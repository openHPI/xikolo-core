# frozen_string_literal: true

require 'spec_helper'

describe CoursePresenter do
  subject { presenter }

  let(:course_id) { generate(:course_id) }
  let(:completed) { false }
  let(:enrollment) { Xikolo::Course::Enrollment.new course_id: course.id, completed: }
  let(:course_params) { {} }
  let(:course) { Xikolo::Course::Course.new course_params.merge id: course_id }
  let(:user_id) { generate(:user_id) }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'user_id' => user_id,
      'user' => {'anonymous' => false}
    )
  end
  let(:permissions) { [] }
  let(:presenter) { described_class.create course, user, [enrollment] }

  it { is_expected.not_to be_external }

  describe '#ribbon' do
    subject(:ribbon) { Capybara.string(presenter.ribbon) }

    context 'with upcoming course' do
      let(:course_params) do
        super().merge status: 'active', start_date: 1.week.from_now, end_date: 2.weeks.from_now
      end

      it 'has a "Starting soon" ribbon' do
        expect(ribbon).to have_content('Starting soon')
      end
    end

    context 'with currently active course' do
      let(:course_params) do
        super().merge status: 'active', start_date: 1.week.ago, end_date: 1.week.from_now
      end

      it 'has a "Started" ribbon' do
        expect(ribbon).to have_content('Started')
      end
    end

    context 'with recently ended course' do
      let(:course_params) { super().merge status: 'active', start_date: 2.weeks.ago, end_date: 1.week.ago }

      it 'has a "Started" ribbon' do
        expect(ribbon).to have_content('Started')
      end
    end
  end

  describe '#recalculation_enabled?' do
    subject(:recalculation) { presenter.recalculation_enabled? }

    it 'recalculation is disabled by default' do
      expect(recalculation).to be false
    end

    context 'with enabled persisted learning evaluation' do
      before do
        xi_config <<~YML
          persisted_learning_evaluation: true
        YML
      end

      it 'recalculation is enabled' do
        expect(recalculation).to be true
      end
    end
  end

  describe '#needs_recalculation?' do
    subject(:needs_recalculation) { presenter.needs_recalculation? }

    it 'no recalculation needed by default' do
      # PLE config option is false by default
      expect(needs_recalculation).to be false
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
