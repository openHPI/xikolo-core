# frozen_string_literal: true

require 'spec_helper'

describe Metrics::EnrollmentsMetric do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_time) { 2.weeks.ago.to_s }
  let(:end_time) { 1.minute.ago.to_s }

  describe '#query' do
    subject { described_class.query user_id, course_id, start_time, end_time }

    before do
      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id:, user_id:}
      ).to_return Stub.json([
        {created_at: 1.week.ago.iso8601(3)},
      ])
    end

    it { is_expected.to eq 1 }
  end
end
