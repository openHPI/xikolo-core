# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessmentDecorator, type: :decorator do
  let(:peer_assessment) { create(:peer_assessment) }
  let(:peer_assessment_decorator) { PeerAssessmentDecorator.new(peer_assessment) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { peer_assessment_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('title') }
    it { is_expected.to include('instructions') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('item_id') }
    it { is_expected.to include('max_points') }
    it { is_expected.to include('grading_hints') }
    it { is_expected.to include('usage_disclaimer') }
    it { is_expected.to include('allow_gallery_opt_out') }
    it { is_expected.to include('allowed_attachments') }
    it { is_expected.to include('allowed_file_types') }
    it { is_expected.to include('max_file_size') }
    it { is_expected.to include('is_team_assessment') }
    it { is_expected.to include('attachments') }
  end
end
