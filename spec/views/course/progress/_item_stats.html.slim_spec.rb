# frozen_string_literal: true

require 'spec_helper'

describe 'course/progress/_item_stats.html.slim', type: :view do
  subject { render_view; rendered }

  let(:render_view) { render 'course/progress/item_stats', stats: }
  let(:stats) { Course::ProgressVisitsStatsPresenter.new user:, total:, percentage: }
  let(:user) { 0 }
  let(:total) { 0 }
  let(:percentage) { 0 }

  context 'counts' do
    let(:user) { 21 }
    let(:total) { 42 }

    it { is_expected.to include '21 of 42' }
  end

  context 'percentage' do
    let(:percentage) { 39 }

    it { is_expected.to include '39' }
  end
end
