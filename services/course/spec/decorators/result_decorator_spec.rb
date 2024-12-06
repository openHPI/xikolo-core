# frozen_string_literal: true

require 'spec_helper'

describe ResultDecorator do
  describe 'to_event' do
    subject(:json) { decorator.to_event.stringify_keys }

    let(:result) { create(:result) }
    let(:decorator) { described_class.new result }

    it { is_expected.to include('course_id') }
    it { is_expected.to include('section_id') }
    it { is_expected.to include('exercise_type') }
    it { is_expected.to include('submission_deadline') }
    it { is_expected.to include('max_points') }
    it { is_expected.to include('created_at') }
  end
end
