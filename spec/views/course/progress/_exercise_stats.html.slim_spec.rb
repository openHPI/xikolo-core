# frozen_string_literal: true

require 'spec_helper'

describe 'course/progress/_exercise_stats.html.slim', type: :view do
  subject { render_view; rendered }

  let(:render_view) { render 'course/progress/exercise_stats', stats: }
  let(:stats) do
    Course::ProgressExerciseStatsPresenter.new total_exercises:,
      submitted_exercises:,
      max_points:,
      submitted_points:
  end
  let(:total_exercises) { 2 }
  let(:submitted_exercises) { 2 }
  let(:max_points) { 0 }
  let(:submitted_points) { 0 }

  context 'count stats' do
    let(:total_exercises) { 42 }
    let(:submitted_exercises) { 17 }

    it { is_expected.to include '17 of 42' }
  end

  context 'point stats' do
    let(:max_points) { 42.4 }
    let(:submitted_points) { 17.3 }

    it { is_expected.to match '17.3.*/42.4' }
  end
end
