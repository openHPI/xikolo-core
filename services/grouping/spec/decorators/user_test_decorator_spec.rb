# frozen_string_literal: true

require 'spec_helper'

describe UserTestDecorator, type: :decorator do
  let(:user_test) { described_class.new create(:user_test) }

  context 'as_json' do
    subject { json }

    let(:json) { user_test.as_json.stringify_keys }

    its(:keys) do
      is_expected.to match_array \
        %w[id name identifier description start_date end_date max_participants
           course_id metric_ids created_at updated_at finished round_robin test_groups_url
           metrics_url filters_url]
    end
  end

  context 'as_json with statistics' do
    subject { json }

    let(:json) { user_test.decorate(context: {statistics: true}).as_json.stringify_keys }

    its(:keys) do
      is_expected.to match_array \
        %w[id name identifier description start_date end_date max_participants
           course_id metric_ids created_at updated_at total_count finished_count
           waiting_count finished round_robin mean test_groups_url metrics_url filters_url required_participants]
    end
  end
end
