# frozen_string_literal: true

require 'spec_helper'

describe 'Prevent password reset bombing', type: :request do
  # Remove localhost from the safelist and reset cache to make tests work as expected
  around do |example|
    removed_safelist = Rack::Attack.safelists.delete('allow from localhost')

    example.run
  ensure
    Rack::Attack.safelists['allow from localhost'] = removed_safelist
  end

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!

    Stub.service(:account, build(:'account:root'))

    Stub.request(
      :account, :post, '/password_resets',
      body: {email: 'p3k@example.de'}.to_json
    ).to_return Stub.json({id: 'the_id', user_id: 'the_user_id'})
  end

  context 'with native login enabled' do
    let(:anonymous_session) do
      super().merge(features: {'account.login' => true})
    end

    it 'blocks after 10th password reset' do
      10.times do
        post '/account/reset', params: {
          reset: {email: 'p3k@example.de'},
        }

        expect(response).to have_http_status :found
      end

      post '/account/reset', params: {
        reset: {email: 'p3k@example.de'},
      }

      expect(response).to have_http_status :service_unavailable
      expect(response.body).to eq 'Blocked due to too many password reset attempts.'

      # Does not block resources other than '/account/reset'
      get '/'
      expect(response).to have_http_status :ok
    end
  end
end
