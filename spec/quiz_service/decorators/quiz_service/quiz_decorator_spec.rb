# frozen_string_literal: true

require 'spec_helper'

describe QuizService::QuizDecorator, type: :decorator do
  let(:quiz) { create(:'quiz_service/quiz') }
  let(:decorator) { described_class.new quiz }

  context 'as_json' do
    subject { json }

    let(:json) { decorator.as_json(api_version: 1).stringify_keys }

    it 'has correct structure' do
      expect(json.keys).to match_array %w[
        id
        instructions
        time_limit_seconds
        allowed_attempts
        max_points
        current_allowed_attempts
        current_unlimited_attempts
        current_time_limit_seconds
        current_unlimited_time
        external_ref_id
        unlimited_attempts
        unlimited_time
        submission_statistic_url
      ]
    end
  end
end
