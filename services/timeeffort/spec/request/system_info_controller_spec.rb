# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemInfoController, type: :request do
  context 'GET /system_info/haproxy' do
    it 'returns a proper status code' do
      get '/system_info/haproxy'
      expect(response).to have_http_status Rack::Utils.status_code(:ok)
    end
  end
end
