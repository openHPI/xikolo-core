# frozen_string_literal: true

require 'spec_helper'

describe AbuseReport, type: :model do
  subject do
    build(:abuse_report,
      user_id:,
      reportable_id: reportable.id,
      reportable_type:)
  end

  let(:user_id) { SecureRandom.uuid }
  let(:reportable) { create(:question) }
  let(:reportable_type) { 'Question' }

  describe 'duplicates' do
    before do
      create(:abuse_report,
        user_id:,
        reportable_id: reportable.id,
        reportable_type:)
    end

    it { is_expected.not_to be_valid }
  end

  describe '#open_reportables' do
    subject { AbuseReport.open_reportables }

    before do
      # single report
      reportable = create(:question)
      create(:abuse_report,
        user_id:,
        reportable:)

      # multiple reports
      reportable = create(:question)
      2.times do
        create(:abuse_report,
          user_id: SecureRandom.uuid,
          reportable:)
      end

      # blocked by teacher
      reportable = create(:question)
      reportable.block!
      create(:abuse_report,
        user_id:,
        reportable:)

      # reviewed by teacher
      reportable = create(:question)
      reportable.review!
      create(:abuse_report,
        user_id:,
        reportable:)
    end

    it { is_expected.to have(3).items }
  end
end
