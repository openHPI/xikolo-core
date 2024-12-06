# frozen_string_literal: true

require 'spec_helper'

describe AnswerDecorator, type: :decorator do
  let(:answer) { AnswerDecorator.new create(:answer) }

  context 'as_json' do
    subject { json }

    let(:json) { answer.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('question_id') }
    it { is_expected.to include('comment') }
    it { is_expected.to include('position') }
    it { is_expected.to include('correct') }
    it { is_expected.to include('type') }
  end
end
