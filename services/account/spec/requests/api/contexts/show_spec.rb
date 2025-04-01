# frozen_string_literal: true

require 'spec_helper'

describe 'Context: Show', type: :request do
  subject(:resource) { api.rel(:context).get({id: record}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:data) { {} }
  let(:record) { create(:context) }

  it 'responds with 200 Ok' do
    expect(resource).to respond_with :ok
  end

  it 'has a self relation' do
    expect(resource.rel(:self)).to eq context_path(record)
  end

  it 'has an ancestors relation' do
    expect(resource.rel(:ancestors).to_s).to eq contexts_path(ancestors: record.id)
  end

  it 'has an ascent relation' do
    expect(resource.rel(:ascent).to_s).to eq contexts_path(ascent: record.id)
  end

  describe 'payload' do
    subject(:payload) { resource.data.reject {|k| k.end_with?('_url') } }

    it 'has matches database record' do
      expect(payload).to match \
        'id' => record.id,
        'parent_id' => record.parent_id,
        'reference_uri' => nil
    end
  end
end
