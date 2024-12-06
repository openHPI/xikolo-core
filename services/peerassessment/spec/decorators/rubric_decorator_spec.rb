# frozen_string_literal: true

require 'spec_helper'

describe RubricDecorator, type: :decorator do
  let(:rubric_decorator) { RubricDecorator.new build(:rubric) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { rubric_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('peer_assessment_id') }
    it { is_expected.to include('hints') }
    it { is_expected.to include('title') }
    it { is_expected.to include('position') }
  end
end
