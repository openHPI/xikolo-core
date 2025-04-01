# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: Update', type: :request do
  subject(:update_request) { api.rel(:calendar_event).patch(payload, params: {id: event.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:event) { create(:calendar_event, title: 'Meeting old') }
  let(:payload) { {} }

  context 'with missing payload' do
    it 'returns the resource' do
      expect(update_request.to_h).to include \
        'id' => event.id,
        'title' => event.title,
        'description' => event.description,
        'all_day' => event.all_day
    end
  end

  context 'with valid payload' do
    let(:payload) { {title: 'Meeting new', all_day: true} }

    it 'returns the updated resource' do
      expect(update_request.to_h).to include \
        'id' => event.id,
        'title' => payload[:title],
        'description' => event.description,
        'all_day' => payload[:all_day]
    end
  end

  context 'with invalid payload' do
    let(:payload) { {title: ''} }

    it 'returns a proper error message' do
      expect { update_request }.to raise_error(Restify::UnprocessableEntity) do |err|
        expect(err.errors).to eq 'title' => ['required']
      end
    end
  end
end
