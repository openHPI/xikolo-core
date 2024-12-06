# frozen_string_literal: true

require 'spec_helper'

describe Channel, '#stage_visual', type: :model do
  subject(:channel) { create(:channel, attributes) }

  let(:attributes) { {} }

  describe '#stage_visual_url' do
    context 'without stage_visual URI' do
      it { expect(channel.stage_visual_url).to be_nil }
    end

    context 'with stage_visual URI' do
      let(:attributes) { {stage_visual_uri: 's3://xikolo-public/channel/stage_visual.png'} }

      it {
        expect(channel.stage_visual_url).to eq \
          'https://s3.xikolo.de/xikolo-public/channel/stage_visual.png'
      }
    end
  end
end
