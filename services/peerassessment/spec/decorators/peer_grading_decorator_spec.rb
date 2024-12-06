# frozen_string_literal: true

require 'spec_helper'

describe PeerGradingDecorator, type: :decorator do
  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:peer_grading_decorator) { PeerGradingDecorator.new assessment.grading_step }

  context 'as_api_v1' do
    subject { json }

    let(:json) { peer_grading_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('optional') }
    it { is_expected.to include('deadline') }
    it { is_expected.to include('position') }
    it { is_expected.to include('open') }
    it { is_expected.to include('required_reviews') }
    it { is_expected.to include('unlock_date') }
  end
end
