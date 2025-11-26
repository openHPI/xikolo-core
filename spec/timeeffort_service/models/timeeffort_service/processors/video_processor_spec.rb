# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeeffortService::Processors::VideoProcessor, type: :model do
  let(:video) { create(:'timeeffort_service/duplicated/video', pip_stream:) }
  let(:pip_stream) { create(:'timeeffort_service/duplicated/stream', duration: 1800) }
  let(:content_type) { 'video' }
  let(:item) { create(:'timeeffort_service/item', content_type:, content_id: video.id) }
  let(:processor) { described_class.new item }

  describe '#initialize' do
    it 'initializes the video correctly' do
      expect(processor.video).to be_nil
    end
  end

  describe '#load_resources!' do
    subject(:load_resources) { processor.load_resources! }

    context 'w/ valid content type' do
      it 'requests the video' do
        expect { load_resources }.not_to raise_error
      end
    end

    context 'w/o valid content type' do
      let(:content_type) { 'quiz' }

      it 'raises an error' do
        expect { load_resources }.to raise_error TimeeffortService::Errors::InvalidItemType
      end
    end

    context 'w/ error while loading video' do
      before { video.destroy! }

      it 'raises an error' do
        expect { load_resources }.to raise_error TimeeffortService::Errors::LoadResourcesError
      end
    end
  end

  describe '#calculate' do
    subject(:calculate_time_effort) { processor.calculate }

    context 'w/ video resource' do
      before do
        processor.instance_variable_set(:@video, video)
      end

      it 'sets the time effort correctly' do
        calculate_time_effort
        expect(processor.time_effort).to eq 1800
      end
    end

    context 'w/o video resource' do
      it 'does not set time effort' do
        expect { calculate_time_effort }.not_to change(processor, :time_effort)
      end
    end
  end
end
