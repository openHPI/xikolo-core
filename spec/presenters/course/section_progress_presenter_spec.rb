# frozen_string_literal: true

require 'spec_helper'

describe Course::SectionProgressPresenter do
  subject(:presenter) do
    described_class.new(course:, section: progress, user:).tap do
      Acfs.run
    end
  end

  shared_examples 'ProgressExerciseStats' do
    it { is_expected.to be_a Course::ProgressExerciseStatsPresenter }

    it 'passes the course instance' do
      expect(stats.instance_variable_get(:@course)).to be_a Xikolo::Course::Course
    end

    it 'passes the user instance' do
      expect(stats.instance_variable_get(:@user)).to be_a Xikolo::Account::User
    end
  end

  let(:course) { Xikolo::Course::Course.new id: SecureRandom.uuid }
  let(:progress) { Xikolo::Course::Progress.new section_progress }
  let(:section_progress) { {'kind' => 'course', 'visits' => {}, 'items' => []} }
  let(:user) { Xikolo::Account::User.new id: SecureRandom.uuid }

  describe '#available?' do
    subject { presenter.available? }

    context 'with empty course' do
      it { is_expected.to be_falsey }
    end

    context 'with not available section' do
      let(:section_progress) do
        super().merge 'available' => false
      end

      it { is_expected.to be_falsey }
    end

    context 'with available section' do
      let(:section_progress) do
        super().merge 'available' => true
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#self_test_stats' do
    subject(:stats) { presenter.self_test_stats }

    it_behaves_like 'ProgressExerciseStats'
  end

  describe '#main_exercise_stats' do
    subject(:stats) { presenter.main_exercise_stats }

    it_behaves_like 'ProgressExerciseStats'
  end

  describe '#bonus_exercise_stats' do
    subject(:stats) { presenter.bonus_exercise_stats }

    it_behaves_like 'ProgressExerciseStats'
  end

  describe '#visits_stats' do
    subject { presenter.visits_stats }

    it { is_expected.to be_a Course::ProgressVisitsStatsPresenter }
  end

  describe '#items' do
    subject(:items) { presenter.items }

    context 'with a empty section' do
      it { is_expected.to eq [] }
    end

    context 'with items' do
      let(:section_progress) do
        super().merge(
          'items' => [
            {'title' => 'test'},
            {'title' => 'test2'},
          ]
        )
      end

      its([0]) { is_expected.to be_a ItemPresenter }
      its([1]) { is_expected.to be_a ItemPresenter }

      it 'passes the item attributes' do
        expect(items[0].title).to eq 'test'
        expect(items[1].title).to eq 'test2'
      end
    end
  end
end
