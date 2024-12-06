# frozen_string_literal: true

require 'spec_helper'

describe ParticipantDecorator, type: :decorator do
  let(:participant_decorator) { ParticipantDecorator.new create(:participant) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { participant_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('expertise') }
    it { is_expected.to include('current_step') }
    it { is_expected.to include('completion') }
    it { is_expected.to include('group_id') }
    # it { should include('complete') }
    # it { should include('skipped') }
  end
end
