# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressExerciseStatsPresenter do
  subject(:presenter) { described_class.new attrs }

  let(:attrs) do
    {
      total_exercises:,
      submitted_exercises:,
      max_points:,
      submitted_points:,
      items:,
    }
  end

  let(:total_exercises) { 1 }
  let(:submitted_exercises) { 1 }
  let(:max_points) { 0 }
  let(:submitted_points) { 0 }
  let(:items) { nil }

  describe '#available?' do
    context 'without any stats' do
      let(:attrs) { nil }

      it { is_expected.not_to be_available }
    end

    context 'without exercises' do
      let(:total_exercises) { 0 }
      let(:submitted_exercises) { 0 }

      it { is_expected.not_to be_available }
    end

    context 'with exercises but none submitted' do
      let(:total_exercises) { 2 }
      let(:submitted_exercises) { 0 }

      it { is_expected.to be_available }
    end

    context 'with exercises and a submitted' do
      let(:total_exercises) { 2 }
      let(:submitted_exercises) { 1 }

      it { is_expected.to be_available }
    end
  end

  describe '#submitted_points' do
    subject(:points) { presenter.submitted_points }

    let(:submitted_points) { 0 }

    it { is_expected.to eq 0 }

    context 'with very accurate values' do
      let(:submitted_points) { 0.213 }

      it 'is rounded to 2 places after comma' do
        expect(points).to eq 0.21
      end
    end
  end

  describe '#my_progress' do
    subject(:progress) { presenter.my_progress }

    context 'with no points' do
      let(:submitted_points) { 0 }
      let(:max_points) { 15 }

      it 'is 0%' do
        expect(progress).to eq 0
      end
    end

    context 'with some points (floor eq round)' do
      let(:submitted_points) { 5 }
      let(:max_points) { 15 }

      it 'is 33%' do
        expect(progress).to eq 33
      end
    end

    context 'with some points (floor neq round)' do
      let(:submitted_points) { 9.5 }
      let(:max_points) { 17 }

      it 'is 55% not 56%' do
        expect(progress).to eq 55
      end
    end

    context 'with all points' do
      let(:submitted_points) { 15 }
      let(:max_points) { 15 }

      it 'is 100%' do
        expect(progress).to eq 100
      end
    end
  end

  describe '#items' do
    subject(:presenter_items) { presenter.items }

    context 'with a empty section' do
      it { is_expected.to eq [] }
    end

    context 'with items' do
      let(:items) do
        [
          {'title' => 'test'},
          {'title' => 'test2'},
        ]
      end

      its([0]) { is_expected.to be_a ItemPresenter }
      its([1]) { is_expected.to be_a ItemPresenter }

      it 'passes the item attributes' do
        expect(presenter_items[0].title).to eq 'test'
        expect(presenter_items[1].title).to eq 'test2'
      end
    end
  end
end
