# frozen_string_literal: true

require 'spec_helper'

describe SelfAssessmentDecorator, type: :decorator do
  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }
  let(:self_assessment_decorator) { SelfAssessmentDecorator.new assessment.self_assessment_step }

  context 'as_api_v1' do
    subject { json }

    let(:json) { self_assessment_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('optional') }
    it { is_expected.to include('deadline') }
    it { is_expected.to include('position') }
    it { is_expected.to include('open') }
    it { is_expected.not_to include('required_reviews') }
    it { is_expected.to include('unlock_date') }
  end
end
