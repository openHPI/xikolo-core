# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Xikolo do
  context 'site' do
    subject { Xikolo.site }

    context '#site' do
      context 'by default' do
        it { should be_unknown }
      end
    end

    context '#site=' do
      before { Xikolo.site = 'unittest' }
      after { Xikolo.site = 'unknown' }

      it { should be_unittest }
      it { should_not be_unknown }
    end
  end

  context 'brand' do
    subject { Xikolo.brand }

    context '#brand' do
      context 'by default' do
        it { should be_xikolo }
      end
    end

    context '#brand=' do
      before { Xikolo.brand = 'company' }
      after { Xikolo.brand = 'xikolo' }

      it { should be_company }
      it { should_not be_xikolo }
    end
  end

  context 'Base URL' do
    subject { Xikolo.base_url }

    describe '#base_url' do
      it { is_expected.to be_a Addressable::URI }

      it 'defaults to https://xikolo.de/' do
        expect(subject.to_s).to eq 'https://xikolo.de/'
      end
    end

    describe '#base_url=' do
      around do |example|
        old = Xikolo.base_url
        Xikolo.base_url = 'ftp://staging.localhost/relative/base/'
        example.run
      ensure
        Xikolo.base_url = old
      end

      it do
        expect(subject.to_hash).to match({
          fragment: nil,
          host: 'staging.localhost',
          password: nil,
          path: '/relative/base/',
          port: nil,
          query: nil,
          scheme: 'ftp',
          user: nil,
        })
      end
    end
  end
end
