# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressPresenter do
  subject { presenter }

  before do
    Stub.service(:course, build(:'course:root'))

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({})
    Stub.request(
      :course, :get, '/progresses',
      query: {user: user.id, course: course.id}
    ).to_return Stub.json([
      *section_progresses,
      course_progress,
    ])
  end

  let(:course_id) { SecureRandom.uuid }
  let(:presenter) do
    described_class.new(user:, course:, progresses:).tap do
      Acfs.run
    end
  end
  let(:user) { Xikolo::Account::User.new id: SecureRandom.uuid }
  let(:course) { Xikolo::Course::Course.new id: course_id }

  let(:progresses) do
    Xikolo::Course::Progress.where user: user.id, course: course.id
  end

  let(:section_progresses) { [] }
  let(:course_progress) { {'kind' => 'course', 'visits' => {}} }

  describe '#with_bonus_exercises?' do
    subject { super().with_bonus_exercises? }

    context 'with empty course' do
      it { is_expected.to be_falsey }
    end

    context 'with course without bonus exercises' do
      let(:course_progress) do
        super().merge(
          'bonus_exercises' => nil
        )
      end

      it { is_expected.to be_falsey }
    end

    context 'with course with bonus exercises' do
      let(:course_progress) do
        super().merge(
          'bonus_exercises' => {
            'total_exercises' => 0,
            'total_points' => 0,
          }
        )
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#available?' do
    subject { super().available? }

    context 'with empty course' do
      it { is_expected.to be_falsey }
    end

    context 'with sections' do
      let(:section_progresses) do
        [
          {'kind' => 'section', 'visits' => {}},
        ]
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#self_test_stats' do
    subject { super().self_test_stats }

    it { is_expected.to be_a Course::ProgressExerciseStatsPresenter }
  end

  describe '#main_exercise_stats' do
    subject { super().main_exercise_stats }

    it { is_expected.to be_a Course::ProgressExerciseStatsPresenter }
  end

  describe '#bonus_exercise_stats' do
    subject { super().bonus_exercise_stats }

    it { is_expected.to be_a Course::ProgressExerciseStatsPresenter }
  end

  describe '#visits_stats' do
    subject { super().visits_stats }

    it { is_expected.to be_a Course::ProgressVisitsStatsPresenter }
  end

  describe '#sections' do
    subject { super().sections }

    context 'with a empty course' do
      it { is_expected.to eq [] }
    end

    context 'with sections' do
      let(:section_progresses) do
        [
          {'kind' => 'section', 'visits' => {}},
          {'kind' => 'section', 'visits' => {}},
        ]
      end

      its([0]) { is_expected.to be_a Course::SectionProgressPresenter }
      its([1]) { is_expected.to be_a Course::SectionProgressPresenter }
    end
  end
end
