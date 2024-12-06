# frozen_string_literal: true

require 'spec_helper'

describe 'GET /.well-known/apple-app-site-association', type: :request do
  subject(:resource) { get '/.well-known/apple-app-site-association' }

  let(:json) { response.parsed_body }

  before do
    Stub.service(
      :account,
      session_url: '/sessions/{id}'
    )
  end

  context 'with the right config' do
    before do
      xi_config <<~YML
        app_links_verification:
          ios:
            app_id_prefix: 9JA89QQLNQ
            bundle_id: de.xikolo.foo
      YML
    end

    it 'returns the valid association file' do
      resource
      expect(response).to have_http_status :ok
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(json).to eq(
        'applinks' => {
          'apps' => [],
          'details' => [
            {
              'appID' => '9JA89QQLNQ.de.xikolo.foo',
              'paths' => [
                '/',
                '/auth/app',
                '/auth/app*',
                '/dashboard',
                '/courses',
                '/courses/*',
                '/channels/*',
              ],
            },
          ],
        }
      )
    end
  end

  context 'without the right config' do
    it 'returns with HTTP Status 404' do
      expect { resource }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
