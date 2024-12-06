# frozen_string_literal: true

require 'spec_helper'
require 'xikolo/s3'

describe Course, '#stage_visual', type: :model do
  subject(:course) { create(:course, attributes) }

  let(:attributes) { {} }

  describe '#stage_visual_url' do
    let(:attributes) { {stage_visual_uri: nil} }

    context 'without stage_visual URI' do
      it { expect(course.stage_visual_url).to be_nil }
    end

    context 'with stage_visual URI' do
      let(:attributes) { {stage_visual_uri: 's3://xikolo-public/course/stage_visual.png'} }

      it {
        expect(course.stage_visual_url).to eq \
          'https://s3.xikolo.de/xikolo-public/course/stage_visual.png'
      }
    end
  end
end
