# frozen_string_literal: true

require 'spec_helper'

describe StepDecorator, type: :decorator do
  let(:step_decorator) { StepDecorator.new Step.new deadline: 1.week.from_now, position: 1, optional: false, open: false }

  context 'as_api_v1' do
    subject { json }

    let(:json) { step_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('optional') }
    it { is_expected.to include('deadline') }
    it { is_expected.to include('unlock_date') }
    it { is_expected.to include('position') }
    it { is_expected.to include('open') }
  end
end
