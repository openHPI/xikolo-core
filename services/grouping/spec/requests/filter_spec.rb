# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter API', type: :request do
  let!(:filters) { create_list(:filter, 10) }
  let(:filter) { filters.first }
  let!(:user_test) { create(:user_test_with_filter) }

  it 'renders all field names' do
    get '/filters', params: {field_names: true}
    expect(json).to eq(Filter.field_names)
  end

  it 'renders all filters' do
    get '/filters'
    expect(json.size).to eq 11
  end

  it 'renders all filters belonging to a user test' do
    get '/filters', params: {user_test_id: user_test.id}
    expect(json.size).to eq 1
  end

  it 'retrieves a specific filter' do
    get "/filters/#{filter.id}"
    expect(response).to be_successful
    expect(json['id']).to eq filter.id
  end
end
