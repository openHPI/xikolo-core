# frozen_string_literal: true

require 'spec_helper'

describe SectionChoiceDecorator do
  subject(:json) { section_choice.as_json(api_version: 1).stringify_keys }

  let(:section_choice) { described_class.new build_stubbed(:section_choice) }

  context 'as_api_v1' do
    it { is_expected.to include('user_id') }
    it { is_expected.to include('section_id') }
    it { is_expected.to include('choice_ids') }
  end
end
