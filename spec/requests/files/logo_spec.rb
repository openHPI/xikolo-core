# frozen_string_literal: true

require 'spec_helper'

describe 'Files: Logo', type: :request do
  subject(:request) { get '/files/logo', params: }

  let(:params) { {} }

  describe 'response' do
    subject { request; response }

    it { is_expected.to have_http_status :found }
    it { is_expected.to redirect_to '/assets/logo-3f63cc7e701f26e85682924b88875b4b9d19777ff8a110267bf3ec13026fb92a.png' }

    it 'is marked as cacheable for a month' do
      request
      expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
    end

    context '?email=1' do
      let(:params) { super().merge(email: '1') }

      it { is_expected.to have_http_status :found }
      it { is_expected.to redirect_to '/assets/logo_mail-f46bb9327a8c663c9ccdbd9a1d45c86d501f89bc505b94eb098091f81b550cba.png' }

      it 'is marked as cacheable for a month' do
        request
        expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
      end
    end
  end
end
