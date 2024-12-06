# frozen_string_literal: true

require 'spec_helper'

describe Imagecrop do
  shared_context 'imgproxy enabled' do
    before do
      xi_config <<~YML
        imgproxy_url: 'https://imgproxy.url'
      YML

      load 'config/initializers/imgproxy.rb'
    end
  end

  describe '#transform' do
    subject(:transformed_url) { described_class.transform(url, params) }

    let(:url) { 'https://foo.bar/image.jpg' }
    let(:params) { {} }

    context 'when no service is enabled' do
      it { expect(transformed_url).to eq(url) }
    end

    context 'when imgproxy is enabled' do
      include_context 'imgproxy enabled'

      describe 'with an invalid image_url' do
        let(:url) { 'https://foo.bar.svg' }

        it { expect(transformed_url).to eq(url) }
      end

      describe 'with a valid image_url' do
        let(:params) do
          {
            crop: 'fill',
            width: 800,
            height: 600,
            gravity: 'no',
            enlarge: 1,
          }
        end

        it { expect(transformed_url).to eq('https://imgproxy.url/1kLl296ZU4qY6tQ6823Xgpuv_OFBhbYFLJNCXSo8bLY/rs:fit:800:600:1/g:no/plain/https://foo.bar/image.jpg') }
      end
    end
  end

  describe '#enabled?' do
    subject(:enabled) { described_class.enabled? }

    context 'when imgproxy is enabled' do
      include_context 'imgproxy enabled'

      it { expect(enabled).to be_truthy }
    end

    context 'when no service is enabled' do
      it { expect(enabled).to be_falsey }
    end
  end

  describe '#origin' do
    subject(:origin) { described_class.origin }

    context 'when imgproxy is enabled' do
      include_context 'imgproxy enabled'

      it { expect(origin).to eq('https://imgproxy.url') }
    end

    context 'when no service is enabled' do
      it { expect(origin).to be_nil }
    end
  end
end
