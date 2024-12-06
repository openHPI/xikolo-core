# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Calendar Events: Update', type: :request do
  subject(:update_request) { api.rel(:calendar_event).patch(params, id: event.id).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:event) { create(:calendar_event, title: 'Meeting old') }
  let(:params) { {} }

  context 'with missing params' do
    it 'returns the resource' do
      expect(update_request.to_h).to include \
        'id' => event.id,
        'title' => event.title,
        'description' => event.description,
        'all_day' => event.all_day
    end
  end

  context 'with valid params' do
    let(:params) { {title: 'Meeting new', all_day: true} }

    it 'returns the updated resource' do
      expect(update_request.to_h).to include \
        'id' => event.id,
        'title' => params[:title],
        'description' => event.description,
        'all_day' => params[:all_day]
    end
  end

  context 'with invalid params' do
    let(:params) { {title: ''} }

    it 'returns a proper error message' do
      expect { update_request }.to raise_error(Restify::UnprocessableEntity) do |err|
        expect(err.errors).to eq 'title' => ['required']
      end
    end
  end
end
