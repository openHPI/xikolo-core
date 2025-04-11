# frozen_string_literal: true

require 'spec_helper'

describe API::SystemInfoController, type: :controller do
  subject(:payload) { JSON.parse(response.body) }

  describe 'GET show' do
    before do
      get :show, params: {id: -1, format: 'json'}
    end

    it 'returns a running state' do
      expect(payload['running']).to be true
    end

    it 'returns the hostname' do
      expect(payload['hostname']).to eq Socket.gethostname
    end
  end
end
