# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: Create', type: :request do
  subject(:create_request) { api.rel(:calendar_events).post(params).value! }

  let(:api) { Restify.new(:test).get.value! }

  let(:collab_space) { create(:collab_space) }
  let(:params) { {} }

  context 'with valid params' do
    let(:params) { attributes_for(:calendar_event, collab_space_id: collab_space.id) }

    it { is_expected.to respond_with :created }

    it 'returns the calendar event' do
      expect(create_request['title']).to eq(params[:title])
    end

    it 'adds a calendar event to the collab space' do
      expect do
        create_request
      end.to change { collab_space.reload.calendar_events.size }.by(1)
    end
  end

  context 'with missing params' do
    it 'returns all error messages' do
      expect { create_request }.to raise_error(Restify::UnprocessableEntity) do |err|
        expect(err.errors).to eq(
          'collab_space' => ['required'],
          'title' => ['required'],
          'start_time' => ['required'],
          'end_time' => ['required'],
          'user_id' => ['required'],
          'category' => %w[required unknown]
        )
      end
    end
  end

  context 'with a blank title' do
    let(:params) do
      attributes_for(:calendar_event, collab_space_id: collab_space.id, title: '')
    end

    it 'returns a proper error message' do
      expect { create_request }.to raise_error(Restify::UnprocessableEntity) do |err|
        expect(err.errors).to eq 'title' => ['required']
      end
    end
  end
end
