# frozen_string_literal: true

require 'spec_helper'

describe CourseService::ItemDecorator do
  subject(:json) { item.as_json(api_version: 1).stringify_keys }

  let(:item) { described_class.new create :'course_service/item' }
  let(:attributes) do
    %w[
      id
      title
      start_date
      end_date
      content_type
      content_id
      section_id
      course_id
      position
      published
      deemphasized_in_nav
      effective_start_date
      effective_end_date
      course_archived
      exercise_type
      max_points
      submission_deadline
      submission_publishing_date
      optional
      section_url
      results_url
      statistics_url
      public_description
      open_mode
      required_item_ids
      minimum_progress_percentage
    ]
  end

  context 'as_api_v1' do
    subject { json }

    let(:attributes) { super() << 'next_item_id' << 'prev_item_id' }

    its(:keys) { is_expected.to match_array(attributes) }
  end

  context 'as collection' do
    let(:item) { described_class.new create(:'course_service/item'), context: {collection: true} }

    its(:keys) { is_expected.to match_array(attributes) }
  end
end
