# frozen_string_literal: true

require 'spec_helper'

describe StatisticDecorator, type: :decorator do
  let(:statistic_decorator) { StatisticDecorator.new statistic }
  let(:statistic) { Statistic.new(peer_assessment_id: assessment.id, concern: 'training') }
  let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics) }

  context 'as_api_v1' do
    subject { json }

    let(:json) { statistic_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('available_submissions') }
  end
end
