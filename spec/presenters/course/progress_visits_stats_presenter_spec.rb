# frozen_string_literal: true

require 'spec_helper'

describe Course::ProgressVisitsStatsPresenter do
  subject { presenter }

  let(:presenter) do
    described_class.new total:, user:, percentage:
  end
  let(:total) { 1 }
  let(:user) { 0 }
  let(:percentage) { 0 }

  describe '#total_count' do
    let(:total) { 42 }

    its(:total_count) { is_expected.to eq total }
  end

  describe '#user_count' do
    let(:user) { 21 }

    its(:user_count) { is_expected.to eq user }
  end

  describe '#user_percentage' do
    let(:percentage) { 99 }

    its(:user_percentage) { is_expected.to eq percentage }
  end
end
