# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Sessions: Create', type: :request do
  around(&With(:csrf_protection, true))

  context 'without CSRF token' do
    it 'renders login page' do
      post '/sessions', params: {
        login: {
          email: 'admin@xikolo.de',
          password: 'secret',
        },
      }

      expect(response).to redirect_to '/sessions/new'
    end
  end
end
