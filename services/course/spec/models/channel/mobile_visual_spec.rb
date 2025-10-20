# frozen_string_literal: true

require 'spec_helper'

describe Channel, '#mobile_visual', type: :model do
  subject(:channel) { create(:'course_service/channel', attributes) }

  let(:attributes) { {} }

  describe '#mobile_visual_url' do
    context 'without mobile_visual URI' do
      it { expect(channel.mobile_visual_url).to be_nil }
    end

    context 'with mobile_visual URI' do
      let(:attributes) { {mobile_visual_uri: 's3://xikolo-public/channel/mobile_visual.png'} }

      it {
        expect(channel.mobile_visual_url).to eq \
          'https://s3.xikolo.de/xikolo-public/channel/mobile_visual.png'
      }
    end
  end
end
