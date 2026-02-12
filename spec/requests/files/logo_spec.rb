# frozen_string_literal: true

require 'spec_helper'

describe 'Files: Logo', type: :request do
  subject(:request) { get '/files/logo', params: }

  let(:params) { {} }

  describe 'response' do
    subject { request; response }

    it { is_expected.to have_http_status :found }
    it { is_expected.to redirect_to %r{/assets/logo-[a-f0-9]+\.png} }

    it 'is marked as cacheable for a month' do
      request
      expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
    end

    context '?email=1' do
      let(:params) { super().merge(email: '1') }

      it { is_expected.to have_http_status :found }
      it { is_expected.to redirect_to %r{/assets/logo_mail-[a-f0-9]+\.png} }

      it 'is marked as cacheable for a month' do
        request
        expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
      end
    end
  end
end
