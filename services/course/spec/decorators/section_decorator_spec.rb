# frozen_string_literal: true

require 'spec_helper'

describe SectionDecorator do
  subject(:json) { section.as_json(api_version: 1).stringify_keys }

  let(:section) { described_class.new create(:section) }

  context 'as_api_v1' do
    it { is_expected.to include('id') }
    it { is_expected.to include('title') }
    it { is_expected.to include('start_date') }
    it { is_expected.to include('end_date') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('published') }
    it { is_expected.to include('optional_section') }
    it { is_expected.to include('position') }
    it { is_expected.to include('alternative_state') }
    it { is_expected.to include('parent_id') }
    it { is_expected.to include('required_section_ids') }
  end
end
