# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: List', type: :request do
  subject(:list_request) do
    api.rel(:collab_space).get({id: params[:collab_space_id]}).value
      .rel(:calendar_events).get.value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:collab_space) { create(:collab_space) }
  let(:another_collab_space) { create(:collab_space) }
  let(:params) { {collab_space_id: collab_space.id} }
  let(:title) { 'Test Meeting #42' }

  it { is_expected.to respond_with :ok }

  context 'with existing calendar events' do
    let(:collab_spaces) do
      create_list(:calendar_event, 5, collab_space_id: collab_space.id)
    end

    before { collab_spaces }

    it 'returns the correct number of calendar events for the collab_space' do
      expect(list_request.size).to eq(5)
    end

    it 'does not return calendar events for another collab_space' do
      create(:calendar_event, collab_space_id: another_collab_space.id)
      expect(list_request.size).to eq(5)
      expect(list_request.map {|e| e.to_h['id'] }).to match_array(collab_spaces.pluck(:id))
    end
  end

  it 'returns a json including the title' do
    create(:calendar_event, collab_space_id: collab_space.id, title:)
    expect(list_request.size).to eq(1)
    expect(list_request[0].to_h).to include \
      'title' => title,
      'all_day' => false
  end
end
