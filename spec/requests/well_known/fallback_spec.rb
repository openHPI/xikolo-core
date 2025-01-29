# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /.well-known/*', type: :request do
  context 'with existing well-known file' do
    before do
      WellKnownFile.create!(
        filename: 'security.txt',
        content: "Security\nContact\nData",
        updated_at: 10.minutes.ago
      )
    end

    it 'responds successfully with text content' do
      get '/.well-known/security.txt'

      expect(response).to have_http_status :ok
      expect(response.body).to eq "Security\nContact\nData"

      # Headers must be converted to hash (`#to_h`) otherwise the `include`
      # matcher will not work because `response.headers` is a Rails object.
      response.headers.to_h.tap do |headers|
        expect(headers).to include 'cache-control' => 'max-age=3600, public'
        expect(headers).to include 'content-type' => include('text/plain')
        expect(headers).to include 'etag', 'last-modified'
      end
    end

    it 'responds with "Not Modified" on matching ETag revalidation' do
      get '/.well-known/security.txt'
      etag = response.headers['ETag']

      get '/.well-known/security.txt', env: {'HTTP_IF_NONE_MATCH' => etag}

      expect(response).to have_http_status :not_modified
      expect(response.body).to eq ''
    end

    it 'responds with "Not Modified" if not modified' do
      get '/.well-known/security.txt', env: {'HTTP_IF_MODIFIED_SINCE' => Time.zone.now.httpdate}

      expect(response).to have_http_status :not_modified
      expect(response.body).to eq ''
    end
  end

  context 'without well-known file' do
    it 'returns with HTTP Status 404' do
      # The `ActionNotFound` exception will be caught by our application's
      # exception handler and rendered with some fancy markup and tracing
      # details by the `ErrorsController`.
      expect { get '/.well-known/security.txt' }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
