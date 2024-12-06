# frozen_string_literal: true

require 'spec_helper'

describe AbuseReportDecorator, type: :decorator do
  subject { json }

  let(:abuse_report) { create(:abuse_report) }
  let(:decorator) { AbuseReportDecorator.new abuse_report }
  let(:json) { decorator.as_json.stringify_keys }

  describe 'as_json' do
    let(:json) { decorator.as_json.stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('reportable_id') }
    it { is_expected.to include('reportable_type') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('url') }
    it { is_expected.to include('created_at') }
    it { is_expected.to include('question_title') }
  end
end
