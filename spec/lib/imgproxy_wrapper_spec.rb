# frozen_string_literal: true

require 'spec_helper'

describe ImgproxyWrapper do
  let(:url) { 'https://foo.bar/image.jpg' }
  let(:params) { {} }

  before do
    xi_config <<~YML
      imgproxy_url: 'https://imgproxy.url'
    YML

    load 'config/initializers/imgproxy.rb'
  end

  describe '#proxy_url' do
    subject(:proxy_url) { described_class.new(url, params).proxy_url }

    context 'with no additional params' do
      it { expect(proxy_url).to eq('https://imgproxy.url/DqnLQx2ecoknDKZFhF8v0hqKx7JrG4OzlxyxEORk1YM/rs:fit:0:0:0/g:ce/plain/https://foo.bar/image.jpg') }
    end

    context 'with aditional params' do
      let(:params) do
        {
          resizing_type: 'fill',
          width: 800,
          height: 600,
          gravity: 'no',
          enlarge: 1,
        }
      end

      it { expect(proxy_url).to eq('https://imgproxy.url/upWa6gHTHfIR04flouriZA5M-bEKfT1vzMYw1jpgmQU/rs:fill:800:600:1/g:no/plain/https://foo.bar/image.jpg') }
    end

    context 'with an invalid resizing type param' do
      let(:params) { {resizing_type: 'invalid'} }

      it { expect { proxy_url }.to raise_error(described_class::InvalidParamError, 'Invalid resizing type: invalid') }
    end

    context 'with an invalid width param' do
      let(:params) { {width: 800.5} }

      it { expect { proxy_url }.to raise_error(described_class::InvalidParamError, 'Invalid width: 800.5') }
    end

    context 'with an invalid height param' do
      let(:params) { {height: -600} }

      it { expect { proxy_url }.to raise_error(described_class::InvalidParamError, 'Invalid height: -600') }
    end

    context 'with an invalid gravity param' do
      let(:params) { {gravity: 'north'} }

      it { expect { proxy_url }.to raise_error(described_class::InvalidParamError, 'Invalid gravity: north') }
    end

    context 'with an invalid enlarge param' do
      let(:params) { {enlarge: 'big'} }

      it { expect { proxy_url }.to raise_error(described_class::InvalidParamError, 'Invalid enlarge: big') }
    end
  end
end
