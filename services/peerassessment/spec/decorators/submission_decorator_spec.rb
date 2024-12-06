# frozen_string_literal: true

require 'spec_helper'

describe SubmissionDecorator, type: :decorator do
  let(:submission) { create(:submission) }
  let(:submission_decorator) { described_class.new submission }

  context 'as_api_v1' do
    subject { json }

    let(:json) { submission_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('text') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('submitted') }
    it { is_expected.to include('disallowed_sample') }
    it { is_expected.to include('gallery_opt_out') }
    it { is_expected.to include('team_name') }
    it { is_expected.to include('attachments') }
  end
end
