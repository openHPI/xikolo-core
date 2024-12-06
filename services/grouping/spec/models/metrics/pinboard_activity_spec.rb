# frozen_string_literal: true

require 'spec_helper'

describe Metrics::PinboardActivity do
  let(:user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:start_date) { 2.weeks.ago.to_s }
  let(:end_date) { 1.minute.ago.to_s }
  let(:name) { 'PinboardActivity' }

  describe '#query' do
    subject { described_class.query user_id, course_id, start_date, end_date }

    before do
      Stub.request(
        :learnanalytics, :get, "/metrics/#{name}",
        query: {course_id:, start_date:, end_date:, user_id:}
      ).to_return Stub.json({
        count: 2,
      })
    end

    it { is_expected.to eq 2 }
  end
end
