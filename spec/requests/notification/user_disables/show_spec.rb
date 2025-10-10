# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Notifications: UserDisables: Show', type: :request do
  subject(:resp) { disable_notifications; response }

  let(:disable_notifications) do
    get '/notification_user_settings/disable', params:
  end

  before do
    Stub.service(:account, build(:'account:root'))
  end

  context 'without the required params' do
    let(:params) { {} }

    it 'renders an error message' do
      expect(resp.status).to eq 302
      expect(flash[:error].first).to eq 'The provided link seems to be invalid.'
    end
  end

  context 'with valid params' do
    let(:params) do
      {
        email: 'john@example.com',
        hash: '88d9a72789e4c8c58b172ac6703c915d89af58c52f62eb40af175a4d4751e21a',
        key: 'announcement',
      }
    end

    it 'renders the form for disabling notifications' do
      expect(resp.status).to eq 200
      expect(resp).to render_template(:show)
      expect(resp.body).to include 'Deactivate notifications',
        'Receiving any more platform news will be deactivated.'
    end
  end
end
