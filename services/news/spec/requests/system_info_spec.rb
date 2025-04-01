# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'System Info', type: :request do
  subject(:info) { api.rel(:system_info).get({id: -1}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:deb_version) { nil }

  before { ENV['DEB_VERSION'] = deb_version }

  after { ENV.delete 'DEB_VERSION' }

  it 'returns a running state' do
    expect(info['running']).to be true
  end

  context 'with debian version number' do
    let(:deb_version) { '1.0+t201310251852+b194-1' }

    it 'returns the package version' do
      expect(info['version']).to eq '1.0'
    end

    it 'returns the build timestamp' do
      expect(info['build_time']).to eq Time.local(2013, 10, 25, 18, 52).iso8601
    end

    it 'returns the build number' do
      expect(info['build_number']).to eq 194
    end
  end

  context 'without debian version number (development' do
    let(:deb_version) { nil }

    it 'returns the package version' do
      expect(info['version']).to eq '0.0'
    end

    it 'returns the build timestamp' do
      t = Time.strptime(Time.now.getlocal.strftime('%Y%m%d%H%M'), '%Y%m%d%H%M')
      expect(info['build_time']).to eq t.iso8601
    end

    it 'returns the build number' do
      expect(info['build_number']).to eq 0
    end
  end

  it 'returns the hostname' do
    expect(info['hostname']).to eq Socket.gethostname
  end
end
