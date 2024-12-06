# frozen_string_literal: true

require 'spec_helper'

describe 'GET /.well-known/assetlinks.json', type: :request do
  subject(:resource) { get '/.well-known/assetlinks.json' }

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
          android:
            package_name: de.xikolo.foo
            sha256_cert_fingerprints:
              - '14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5'
      YML
    end

    it 'returns the valid digital asset links file' do
      resource
      expect(response).to have_http_status :ok
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(json).to eq [
        {
          'relation' => %w[
            delegate_permission/common.handle_all_urls
            delegate_permission/common.use_as_origin
          ],
          'target' => {
            'namespace' => 'android_app',
            'package_name' => 'de.xikolo.foo',
            'sha256_cert_fingerprints' => [
              '14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5',
            ],
          },
        },
      ]
    end
  end

  context 'without the right config' do
    it 'returns with HTTP Status 404' do
      expect { resource }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
