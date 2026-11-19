# frozen_string_literal: true

require 'spec_helper'

describe Course::EnrollmentsStatistics do
  subject(:stats) { described_class.new(course:) }

  let(:course) do
    create(:course, start_date: 2.weeks.ago, end_date: 1.week.ago, enrollment_delta: delta)
  end
  let(:delta) { 0 }
  let(:another_course) { create(:course) }

  before do
    create_list(:enrollment, 2, course:, created_at: 3.weeks.ago)
    create_list(:enrollment, 3, course:, created_at: 10.days.ago)
    create_list(:enrollment, 1, course:, created_at: 1.day.ago)
    create_list(:enrollment, 2, course: another_course)
  end

  describe '#current' do
    subject { stats.current }

    it { is_expected.to eq 6 }

    context 'with enrollment delta' do
      let(:delta) { 500 }

      it { is_expected.to eq 506 }
    end
  end
end
