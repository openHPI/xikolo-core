# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::AbuseReport, type: :model do
  subject do
    build(:'pinboard_service/abuse_report',
      user_id:,
      reportable_id: reportable.id,
      reportable_type:)
  end

  let(:user_id) { SecureRandom.uuid }
  let(:reportable) { create(:'pinboard_service/question') }
  let(:reportable_type) { 'PinboardService::Question' }

  describe 'duplicates' do
    before do
      create(:'pinboard_service/abuse_report',
        user_id:,
        reportable_id: reportable.id,
        reportable_type:)
    end

    it { is_expected.not_to be_valid }
  end

  describe '#open_reportables' do
    subject { PinboardService::AbuseReport.open_reportables }

    before do
      # single report
      reportable = create(:'pinboard_service/question')
      create(:'pinboard_service/abuse_report',
        user_id:,
        reportable:)

      # multiple reports
      reportable = create(:'pinboard_service/question')
      2.times do
        create(:'pinboard_service/abuse_report',
          user_id: SecureRandom.uuid,
          reportable:)
      end

      # blocked by teacher
      reportable = create(:'pinboard_service/question')
      reportable.block!
      create(:'pinboard_service/abuse_report',
        user_id:,
        reportable:)

      # reviewed by teacher
      reportable = create(:'pinboard_service/question')
      reportable.review!
      create(:'pinboard_service/abuse_report',
        user_id:,
        reportable:)
    end

    it { is_expected.to have(3).items }
  end
end
