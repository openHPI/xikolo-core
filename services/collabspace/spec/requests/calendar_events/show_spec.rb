# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: Show', type: :request do
  subject(:show_request) { api.rel(:calendar_event).get(id: event.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:event) { create(:calendar_event) }

  it { is_expected.to respond_with :ok }

  it 'returns the right resource' do
    expect(show_request['id']).to eq event.id
  end

  it 'includes all fields' do
    expect(show_request).to include(
      'id',
      'title',
      'collab_space_id',
      'start_time',
      'end_time',
      'category',
      'user_id',
      'all_day'
    )
  end
end
