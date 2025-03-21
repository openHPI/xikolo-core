# frozen_string_literal: true

require 'spec_helper'

describe SystemInfoController, type: :controller do
  subject(:json) { JSON[response.body].with_indifferent_access }

  let(:params)  { {} }

  describe 'GET show' do
    let(:deb_version) { nil }

    before do
      ENV['DEB_VERSION'] = deb_version
      get :show, params: {id: -1}
    end

    after do
      ENV.delete 'DEB_VERSION'
    end

    it 'returns a running state' do
      expect(json[:running]).to be true
    end

    context 'with debian version number' do
      let(:deb_version) { '1.0+t201310251852+b194-1' }

      it 'returns the package version' do
        expect(json[:version]).to eq '1.0'
      end

      it 'returns the build timestamp' do
        expect(json[:build_time]).to eq Time.local(2013, 10, 25, 18, 52).iso8601
      end

      it 'returns the build number' do
        expect(json[:build_number]).to eq 194
      end
    end

    context 'without debian version number (development' do
      let(:deb_version) { nil }

      it 'returns the package version' do
        expect(json[:version]).to eq '0.0'
      end

      it 'returns the build timestamp' do
        t = Time.strptime(Time.now.getlocal.strftime('%Y%m%d%H%M'), '%Y%m%d%H%M')
        expect(json[:build_time]).to eq t.iso8601
      end

      it 'returns the build number' do
        expect(json[:build_number]).to eq 0
      end
    end

    it 'returns the hostname' do
      expect(json[:hostname]).to eq Socket.gethostname
    end
  end
end
