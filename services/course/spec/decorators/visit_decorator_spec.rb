# frozen_string_literal: true

require 'spec_helper'

describe VisitDecorator do
  let(:visit) { described_class.new create(:'course_service/visit') }

  context 'as_api_v1' do
    subject(:json) { visit.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('item_id') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('created_at') }
    it { is_expected.to include('updated_at') }
  end

  context 'to_event' do
    subject(:json) { visit.to_event.stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('item_id') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('created_at') }
    it { is_expected.to include('updated_at') }
    it { is_expected.to include('content_type') }
    it { is_expected.to include('content_id') }
    it { is_expected.to include('exercise_type') }
    it { is_expected.to include('submission_deadline') }
    it { is_expected.to include('max_points') }
    it { is_expected.to include('course_id') }
    it { is_expected.to include('section_id') }

    its(['content_type']) { is_expected.to eq 'video' }
  end
end
