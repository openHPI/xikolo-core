# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication: Mobile SSO', type: :request do
  it 'sets in-app cookie and redirects to WHO SSO' do
    get '/?in_app=true&redirect_to=/auth/who'

    expect(response.cookies['in_app']).to eq('1')
    expect(response).to redirect_to('/auth/who')
  end

  describe 'invalid authentication' do
    it 'does not redirect to not allowed paths' do
      get '/?in_app=true&redirect_to=/auth/foobar'

      expect(response).not_to redirect_to('/auth/foobar')
    end

    it 'does not redirect to external domains' do
      get '/?in_app=true&redirect_to=http://www.evildomain.com'

      expect(response).not_to redirect_to('http://www.evildomain.com')
    end

    it 'does not redirect to external domains with allowed param' do
      get '/?in_app=true&redirect_to=http://www.evildomain.com/auth/sap'

      expect(response).not_to redirect_to('http://www.evildomain.com/auth/sap')
    end
  end
end
