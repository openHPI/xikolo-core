# frozen_string_literal: true

require 'spec_helper'

describe AssignmentSubmissionDecorator, type: :decorator do
  let(:assignment_submission_decorator) { AssignmentSubmissionDecorator.new create :assignment_submission }

  context 'as_api_v1' do
    subject { json }

    let(:json) { assignment_submission_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('optional') }
    it { is_expected.to include('deadline') }
    it { is_expected.to include('position') }
    it { is_expected.to include('open') }
    it { is_expected.to include('unlock_date') }
  end
end
