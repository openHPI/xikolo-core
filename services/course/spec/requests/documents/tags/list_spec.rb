# frozen_string_literal: true

require 'spec_helper'

describe 'Document Tags: List', type: :request do
  subject(:action) { api.rel(:documents_tags).get(params).value! }

  before do
    create(:'course_service/document', tags: %w[tag1 franz frafra])
    create(:'course_service/document', tags: %w[tag2 franz hihi])
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(5).items }

  it 'orders by count and include all tags' do
    expect(action.first).to eq 'franz'
    expect(action).to match_array %w[franz frafra tag2 tag1 hihi]
  end
end
