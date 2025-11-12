# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::SystemInfoController, type: :controller do
  routes { PinboardService::Engine.routes }
  subject(:system_info) { JSON.parse(response.body) }

  let(:default_params) { {format: 'json'} }
  let(:params)  { {} }

  describe 'GET show' do
    before do
      get :show, params: {id: -1, format: 'json'}
    end

    it 'returns a running state' do
      expect(system_info['running']).to be true
    end

    it 'returns the hostname' do
      expect(system_info['hostname']).to eq Socket.gethostname
    end
  end
end
