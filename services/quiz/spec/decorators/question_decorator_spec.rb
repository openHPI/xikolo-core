# frozen_string_literal: true

require 'spec_helper'

describe QuestionDecorator, type: :decorator do
  let(:question) { create(:multiple_choice_question) }
  let(:decorator) { described_class.new question }

  context 'as_json' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('quiz_id') }
    it { is_expected.to include('text') }
    it { is_expected.to include('points') }
    it { is_expected.to include('explanation') }
    it { is_expected.to include('shuffle_answers') }
    it { is_expected.to include('type') }
    it { is_expected.to include('position') }
    it { is_expected.to include('exclude_from_recap') }
    it { is_expected.to include('eligible_for_recap') }
    it { is_expected.to include('submission_statistic_url') }
  end
end
