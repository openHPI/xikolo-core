# frozen_string_literal: true

require 'spec_helper'

describe 'Files: Logo', type: :request do
  subject(:request) { get '/files/logo', params: }

  let(:params) { {} }

  describe 'response' do
    subject { request; response }

    it { is_expected.to have_http_status :found }
    it { is_expected.to redirect_to '/assets/logo-8123666564b22f4c936b10bfb3d74d16a78ef2ec18a7c6acf20d96546519ddc9.png' }

    it 'is marked as cacheable for a month' do
      request
      expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
    end

    context '?email=1' do
      let(:params) { super().merge(email: '1') }

      it { is_expected.to have_http_status :found }
      it { is_expected.to redirect_to '/assets/logo_mail-e2ff1070eda1f62a7ca2c61619dd19d7197c165ed1df48df22b3301b3e6c4983.png' }

      it 'is marked as cacheable for a month' do
        request
        expect(response.headers['Cache-Control']).to eq 'max-age=2629746, public'
      end
    end
  end
end
