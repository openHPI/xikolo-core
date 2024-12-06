# frozen_string_literal: true

require 'spec_helper'

describe 'PeerAssessment: Index', type: :request do
  subject(:index) { api.rel(:peer_assessments).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {course_id:} }
  let(:course_id) { generate(:course_id) }
  let(:item_id) { generate(:item_id) }
  let(:peer_assessments) do
    (1..51).map do |time|
      create(:peer_assessment, title: "PA n.#{time}", instructions: 'Do something', course_id:, item_id:)
    end
  end

  before { peer_assessments }

  it 'returns a paginated response of 50 results per page' do
    expect(index.size).to eq 50
    expect(index.response.headers['X_PER_PAGE']).to eq '50'
    expect(index.response.headers['X_TOTAL_COUNT']).to eq '51'
    expect(index.response.headers['X_TOTAL_PAGES']).to eq '2'
    expect(index.response.headers['X_CURRENT_PAGE']).to eq '1'
    expect(index.response.headers['LINK']).to include('page=1>; rel="first"')
    expect(index.response.headers['LINK']).to include('page=2>; rel="next"')
    expect(index.response.headers['LINK']).to include('page=2>; rel="last"')
  end

  it 'contains specific attributes' do
    expect(index.map(&:keys)).to all contain_exactly(
      'allow_gallery_opt_out',
      'allowed_attachments',
      'allowed_file_types',
      'attachments',
      'course_id',
      'file_url',
      'files_url',
      'gallery_entries',
      'grading_hints',
      'id',
      'instructions',
      'is_team_assessment',
      'item_id',
      'max_file_size',
      'max_points',
      'title',
      'usage_disclaimer',
      'user_steps_url'
    )
  end
end
