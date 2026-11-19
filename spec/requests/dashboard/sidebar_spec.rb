# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard: Sidebar', type: :request do
  subject(:show_dashboard) { get '/dashboard', headers: }

  context 'as anonymous user' do
    it 'redirects to the login page' do
      show_dashboard
      expect(request).to redirect_to 'http://www.example.com/sessions/new'
    end
  end
end
