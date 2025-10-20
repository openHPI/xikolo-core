# frozen_string_literal: true

require 'spec_helper'

describe Channel, '#logo', type: :model do
  subject(:channel) { create(:'course_service/channel', attributes) }

  let(:attributes) { {} }

  describe '#logo_url' do
    context 'without logo URI' do
      it { expect(channel.logo_url).to be_nil }
    end

    context 'with logo URI' do
      let(:attributes) { {logo_uri: 's3://xikolo-public/channel/logo.png'} }

      it {
        expect(channel.logo_url).to eq \
          'https://s3.xikolo.de/xikolo-public/channel/logo.png'
      }
    end
  end
end
