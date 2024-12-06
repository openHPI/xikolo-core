# frozen_string_literal: true

require 'spec_helper'

describe RubricOptionDecorator, type: :decorator do
  let(:rubric_option_decorator) { RubricOptionDecorator.new create(:rubric_option) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { rubric_option_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('rubric_id') }
    it { is_expected.to include('description') }
    it { is_expected.to include('points') }
  end
end
