# frozen_string_literal: true

require 'spec_helper'

describe SubmissionFileDecorator, type: :decorator do
  let(:file) { create(:submission_file) }
  let(:decorator) { described_class.new(file) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('name') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('size') }
    it { is_expected.to include('mime_type') }
    it { is_expected.to include('download_url') }
    it { is_expected.to include('created_at') }
  end
end
