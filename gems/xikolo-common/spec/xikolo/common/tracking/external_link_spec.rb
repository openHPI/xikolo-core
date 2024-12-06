# frozen_string_literal: true

require 'xikolo/common/tracking/external_link'
require 'uri'

RSpec.describe Xikolo::Common::Tracking::ExternalLink do
  let(:link) { described_class.new url, domain, params }
  let(:url) { 'http://www.google.de' }
  let(:domain) { 'open.xikolo.org' }
  let(:params) { {} }

  subject { link }

  describe '#to_s' do
    subject { super().to_s }

    it { is_expected.to be_a String }

    describe '(url)' do
      subject { URI.parse super() }

      it 'should be valid' do
        is_expected.to be_truthy
      end

      it 'should contain a url parameter' do
        expect(subject.query).to include 'url='
      end

      it 'should contain a checksum parameter' do
        expect(subject.query).to include 'checksum='
      end
    end
  end

  describe '#valid?' do
    subject { super().valid? received_checksum }

    context 'with random string' do
      let(:received_checksum) { 'abcde' }

      it { is_expected.to be false }
    end

    context 'with correct checksum' do
      let(:received_checksum) { link.checksum }

      it { is_expected.to be true }
    end
  end

  context 'with Addressable::URI domain' do
    let(:domain) { Addressable::URI.parse('http://mooc.house/') }

    it 'can be serialized' do
      expect(link.to_s).to start_with 'http://mooc.house/go/link?'
    end

    it 'produces a valid checksum' do
      expect(link.valid?(link.checksum)).to be true
    end
  end
end
