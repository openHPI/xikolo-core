# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Sidebar', type: :request do
  subject(:show_dashboard) { get '/dashboard', headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { generate(:user_id) }
  let(:features) { {} }

  before do
    stub_user_request(id: user_id, features:)
  end

  context 'as anonymous user' do
    let(:headers) { {} }

    it 'redirects to the login page' do
      show_dashboard
      expect(request).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
